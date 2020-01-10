import SnippetHeader from '~/snippets/components/snippet_header.vue';
import DeleteSnippetMutation from '~/snippets/mutations/deleteSnippet.mutation.graphql';
import { ApolloMutation } from 'vue-apollo';
import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

describe('Snippet header component', () => {
  let wrapper;
  const snippet = {
    snippet: {
      id: 'gid://gitlab/PersonalSnippet/50',
      title: 'The property of Thor',
      visibilityLevel: 'private',
      webUrl: 'http://personal.dev.null/42',
      userPermissions: {
        adminSnippet: true,
        updateSnippet: true,
        reportSnippet: false,
      },
      project: null,
      author: {
        name: 'Thor Odinson',
      },
    },
  };
  const mutationVariables = {
    mutation: DeleteSnippetMutation,
    variables: {
      id: snippet.snippet.id,
    },
  };
  const errorMsg = 'Foo bar';
  const err = { message: errorMsg };

  const resolveMutate = jest.fn(() => Promise.resolve());
  const rejectMutation = jest.fn(() => Promise.reject(err));

  const mutationTypes = {
    RESOLVE: resolveMutate,
    REJECT: rejectMutation,
  };

  function createComponent({
    loading = false,
    permissions = {},
    mutationRes = mutationTypes.RESOLVE,
  } = {}) {
    const defaultProps = Object.assign({}, snippet);
    if (permissions) {
      Object.assign(defaultProps.snippet.userPermissions, {
        ...permissions,
      });
    }
    const $apollo = {
      queries: {
        canCreateSnippet: {
          loading,
        },
      },
      mutate: mutationRes,
    };

    wrapper = shallowMount(SnippetHeader, {
      mocks: { $apollo },
      propsData: {
        ...defaultProps,
      },
      stubs: {
        ApolloMutation,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders itself', () => {
    createComponent();
    expect(wrapper.find('.detail-page-header').exists()).toBe(true);
  });

  it('renders action buttons based on permissions', () => {
    createComponent({
      permissions: {
        adminSnippet: false,
        updateSnippet: false,
      },
    });
    expect(wrapper.findAll(GlButton).length).toEqual(0);

    createComponent({
      permissions: {
        adminSnippet: true,
        updateSnippet: false,
      },
    });
    expect(wrapper.findAll(GlButton).length).toEqual(1);

    createComponent({
      permissions: {
        adminSnippet: true,
        updateSnippet: true,
      },
    });
    expect(wrapper.findAll(GlButton).length).toEqual(2);

    createComponent({
      permissions: {
        adminSnippet: true,
        updateSnippet: true,
      },
    });
    wrapper.setData({
      canCreateSnippet: true,
    });
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.findAll(GlButton).length).toEqual(3);
    });
  });

  it('renders modal for deletion of a snippet', () => {
    createComponent();
    expect(wrapper.find(GlModal).exists()).toBe(true);
  });

  describe('Delete mutation', () => {
    const { location } = window;

    beforeEach(() => {
      delete window.location;
      window.location = {
        pathname: '',
      };
    });

    afterEach(() => {
      window.location = location;
    });

    it('dispatches a mutation to delete the snippet with correct variables', () => {
      createComponent();
      wrapper.vm.deleteSnippet();
      expect(mutationTypes.RESOLVE).toHaveBeenCalledWith(mutationVariables);
    });

    it('sets error message if mutation fails', () => {
      createComponent({ mutationRes: mutationTypes.REJECT });
      expect(Boolean(wrapper.vm.errorMessage)).toBe(false);

      wrapper.vm.deleteSnippet();
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.errorMessage).toEqual(errorMsg);
      });
    });

    it('closes modal and redirects to snippets listing in case of successful mutation', () => {
      createComponent();
      wrapper.vm.closeDeleteModal = jest.fn();

      wrapper.vm.deleteSnippet();
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.closeDeleteModal).toHaveBeenCalled();
        expect(window.location.pathname).toEqual('dashboard/snippets');
      });
    });
  });
});
