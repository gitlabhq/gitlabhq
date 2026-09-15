import Vue from 'vue';
import gql from 'graphql-tag';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo, { createMockClient } from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

const postQuery = gql`
  query getPost($id: ID!) {
    post(id: $id) {
      id
      title
    }
  }
`;

const postMutation = gql`
  mutation updatePost($id: ID!) {
    updatePost(id: $id) {
      id
      title
    }
  }
`;

const postResponse = (title) => ({
  data: { post: { __typename: 'Post', id: '1', title } },
});

// Exercises the option-API surface used across the repo: smart query with
// variables/update/error/skip, imperative $apollo access, teardown.
const createPostComponent = (apolloOverrides = {}) => ({
  name: 'PostComponent',
  apollo: {
    post: {
      query: postQuery,
      variables() {
        return { id: this.postId };
      },
      update(data) {
        return data.post.title;
      },
      error(error) {
        this.lastError = error;
      },
      skip() {
        return this.skipped;
      },
      ...apolloOverrides,
    },
  },
  data() {
    return { post: null, postId: '1', skipped: false, lastError: null };
  },
  template: '<button @click="skipped = false">{{ post }}</button>',
});

describe('vue-apollo option API (install parity probe)', () => {
  describe('provider passed as mount option', () => {
    it('runs a smart query with variables and update, and supports refetch', async () => {
      const handler = jest.fn().mockResolvedValue(postResponse('Hello'));
      const wrapper = mount(createPostComponent(), {
        apolloProvider: createMockApollo([[postQuery, handler]]),
      });

      expect(wrapper.vm.$apollo.queries.post.loading).toBe(true);

      await waitForPromises();

      expect(handler).toHaveBeenCalledWith({ id: '1' });
      expect(wrapper.text()).toBe('Hello');
      expect(wrapper.vm.$apollo.queries.post.loading).toBe(false);

      await wrapper.vm.$apollo.queries.post.refetch();
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(2);
    });

    it('calls the error hook with the failure', async () => {
      const handler = jest.fn().mockRejectedValue(new Error('boom'));
      const wrapper = mount(createPostComponent(), {
        apolloProvider: createMockApollo([[postQuery, handler]]),
      });

      await waitForPromises();

      expect(wrapper.vm.lastError).toEqual(expect.any(Error));
      expect(wrapper.vm.post).toBe(null);
    });

    it('does not run a skipped query until skip flips', async () => {
      const handler = jest.fn().mockResolvedValue(postResponse('Later'));
      const wrapper = mount(createPostComponent(), {
        apolloProvider: createMockApollo([[postQuery, handler]]),
        data() {
          return { skipped: true };
        },
      });

      await waitForPromises();
      expect(handler).not.toHaveBeenCalled();

      await wrapper.find('button').trigger('click');
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(1);
      expect(wrapper.text()).toBe('Later');
    });

    it('routes queries to a named client', async () => {
      const namedHandler = jest.fn().mockResolvedValue(postResponse('From named'));
      const apolloProvider = new VueApollo({
        defaultClient: createMockClient(),
        clients: {
          namedClient: createMockClient([[postQuery, namedHandler]]),
        },
      });
      const wrapper = mount(createPostComponent({ client: 'namedClient' }), { apolloProvider });

      await waitForPromises();

      expect(namedHandler).toHaveBeenCalledWith({ id: '1' });
      expect(wrapper.text()).toBe('From named');
    });

    it('exposes $apollo.mutate bound to the provider', async () => {
      const mutationHandler = jest.fn().mockResolvedValue({
        data: { updatePost: { __typename: 'Post', id: '1', title: 'Updated' } },
      });
      const wrapper = mount(
        { name: 'MutatingComponent', template: '<div></div>' },
        { apolloProvider: createMockApollo([[postMutation, mutationHandler]]) },
      );

      await wrapper.vm.$apollo.mutate({ mutation: postMutation, variables: { id: '1' } });

      expect(mutationHandler).toHaveBeenCalledWith({ id: '1' });
    });

    it('tears down smart queries on destroy and keeps $apollo readable', async () => {
      const handler = jest.fn().mockResolvedValue(postResponse('Hello'));
      const wrapper = mount(createPostComponent(), {
        apolloProvider: createMockApollo([[postQuery, handler]]),
      });

      await waitForPromises();

      const query = wrapper.vm.$apollo.queries.post;

      wrapper.destroy();

      // eslint-disable-next-line no-underscore-dangle
      expect(query._destroyed).toBe(true);
      // vue-apollo v3 parity: $apollo stays accessible after unmount
      expect(typeof wrapper.vm.$apollo.mutate).toBe('function');
    });
  });

  describe('component-level apolloProvider option', () => {
    it('binds the component and its descendants to the component provider', async () => {
      const handler = jest.fn().mockResolvedValue(postResponse('Subtree'));
      const componentProvider = new VueApollo({
        defaultClient: createMockClient([[postQuery, handler]]),
      });
      const child = createPostComponent();
      const host = {
        name: 'HostWithProvider',
        apolloProvider: componentProvider,
        components: { ChildWithQuery: child },
        template: '<div><child-with-query /></div>',
      };

      const wrapper = mount(host);

      await waitForPromises();

      expect(handler).toHaveBeenCalledWith({ id: '1' });
      expect(wrapper.text()).toBe('Subtree');
    });

    it('resolves the provider through an ancestor with a narrow exposed API', async () => {
      const handler = jest.fn().mockResolvedValue(postResponse('Behind expose'));
      // `expose` makes children see this ancestor through an expose proxy
      // that hides regular instance properties (the shape of
      // @gitlab/ui's BaseDropdown), so provider resolution must not rely on
      // reading cached state through `$parent`.
      const middle = {
        name: 'ExposingMiddle',
        expose: [],
        components: { ChildWithQuery: createPostComponent() },
        template: '<div><child-with-query /></div>',
      };

      const wrapper = mount(middle, {
        apolloProvider: createMockApollo([[postQuery, handler]]),
      });

      await waitForPromises();

      expect(handler).toHaveBeenCalledWith({ id: '1' });
      expect(wrapper.text()).toBe('Behind expose');
    });

    it('is overridden by a mount-time apolloProvider on the mounted component', async () => {
      const definitionHandler = jest.fn().mockResolvedValue(postResponse('From definition'));
      const mountHandler = jest.fn().mockResolvedValue(postResponse('From mount'));
      const definitionProvider = new VueApollo({
        defaultClient: createMockClient([[postQuery, definitionHandler]]),
      });
      const component = {
        ...createPostComponent(),
        apolloProvider: definitionProvider,
      };

      const wrapper = mount(component, {
        apolloProvider: createMockApollo([[postQuery, mountHandler]]),
      });

      await waitForPromises();

      expect(mountHandler).toHaveBeenCalledWith({ id: '1' });
      expect(definitionHandler).not.toHaveBeenCalled();
      expect(wrapper.text()).toBe('From mount');
    });
  });
});

describe('$apollo availability in child components created via parent option', () => {
  it('child instance created with new Vue and parent option has $apollo', () => {
    const apolloProvider = createMockApollo([]);

    const parentApp = new Vue({
      el: document.createElement('div'),
      name: 'ParentApp',
      apolloProvider,
      render() {
        return null;
      },
    });

    expect(parentApp.$apollo).toBeDefined();

    let childApollo = null;

    // eslint-disable-next-line no-new
    new Vue({
      el: document.createElement('div'),
      name: 'ChildApp',
      parent: parentApp,
      mounted() {
        childApollo = this.$apollo;
      },
      render() {
        return null;
      },
    });

    expect(childApollo).toBeDefined();
    expect(typeof childApollo.mutate).toBe('function');
  });

  it('child $apollo remains usable after parent is destroyed', () => {
    const apolloProvider = createMockApollo([]);

    const wrapper = mount(
      {
        name: 'ParentWithApollo',
        template: '<div><ChildComp ref="child" /></div>',
        components: {
          ChildComp: {
            name: 'ChildComp',
            template: '<div></div>',
            methods: {
              getApollo() {
                return this.$apollo;
              },
            },
          },
        },
      },
      { apolloProvider },
    );

    const childVm = wrapper.findComponent({ name: 'ChildComp' }).vm;

    expect(childVm.getApollo()).toBeDefined();
    expect(typeof childVm.getApollo().mutate).toBe('function');

    wrapper.destroy();

    const apollo = childVm.getApollo();
    expect(apollo).toBeDefined();
    expect(typeof apollo.mutate).toBe('function');
  });
});
