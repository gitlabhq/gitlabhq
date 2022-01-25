import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import ItemTitle from '~/work_items/components/item_title.vue';
import { resolvers } from '~/work_items/graphql/resolvers';

Vue.use(VueApollo);

describe('Create work item component', () => {
  let wrapper;
  let fakeApollo;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(ItemTitle);
  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');

  const createComponent = ({ data = {}, props = {} } = {}) => {
    fakeApollo = createMockApollo([], resolvers);
    wrapper = shallowMount(CreateWorkItem, {
      apolloProvider: fakeApollo,
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        ...props,
      },
      mocks: {
        $router: {
          go: jest.fn(),
          push: jest.fn(),
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('does not render error by default', () => {
    createComponent();

    expect(findAlert().exists()).toBe(false);
  });

  it('renders a disabled Create button when title input is empty', () => {
    createComponent();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  describe('when displayed on a separate route', () => {
    beforeEach(() => {
      createComponent();
    });

    it('redirects to the previous page on Cancel button click', () => {
      findCancelButton().vm.$emit('click');

      expect(wrapper.vm.$router.go).toHaveBeenCalledWith(-1);
    });

    it('redirects to the work item page on successful mutation', async () => {
      findTitleInput().vm.$emit('title-input', 'Test title');

      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(wrapper.vm.$router.push).toHaveBeenCalled();
    });

    it('adds right margin for create button', () => {
      expect(findCreateButton().classes()).toContain('gl-mr-3');
    });

    it('does not add right margin for cancel button', () => {
      expect(findCancelButton().classes()).not.toContain('gl-mr-3');
    });
  });

  describe('when displayed in a modal', () => {
    beforeEach(() => {
      createComponent({
        props: {
          isModal: true,
        },
      });
    });

    it('emits `closeModal` event on Cancel button click', () => {
      findCancelButton().vm.$emit('click');

      expect(wrapper.emitted('closeModal')).toEqual([[]]);
    });

    it('emits `onCreate` on successful mutation', async () => {
      const mockTitle = 'Test title';
      findTitleInput().vm.$emit('title-input', 'Test title');

      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted('onCreate')).toEqual([[mockTitle]]);
    });

    it('does not right margin for create button', () => {
      expect(findCreateButton().classes()).not.toContain('gl-mr-3');
    });

    it('adds right margin for cancel button', () => {
      expect(findCancelButton().classes()).toContain('gl-mr-3');
    });
  });

  it('hides the alert on dismissing the error', async () => {
    createComponent({ data: { error: true } });

    expect(findAlert().exists()).toBe(true);

    findAlert().vm.$emit('dismiss');
    await nextTick();

    expect(findAlert().exists()).toBe(false);
  });

  it('displays an initial title if passed', () => {
    const initialTitle = 'Initial Title';
    createComponent({
      props: { initialTitle },
    });
    expect(findTitleInput().props('initialTitle')).toBe(initialTitle);
  });

  describe('when title input field has a text', () => {
    beforeEach(() => {
      const mockTitle = 'Test title';
      createComponent();
      findTitleInput().vm.$emit('title-input', mockTitle);
    });

    it('renders a non-disabled Create button', () => {
      expect(findCreateButton().props('disabled')).toBe(false);
    });

    // TODO: write a proper test here when we have a backend implementation
    it.todo('shows an alert on mutation error');
  });
});
