import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import ItemTitle from '~/work_items/components/item_title.vue';
import { resolvers } from '~/work_items/graphql/resolvers';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import { projectWorkItemTypesQueryResponse } from '../mock_data';

Vue.use(VueApollo);

describe('Create work item component', () => {
  let wrapper;
  let fakeApollo;

  const querySuccessHandler = jest.fn().mockResolvedValue(projectWorkItemTypesQueryResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(ItemTitle);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findContent = () => wrapper.find('[data-testid="content"]');
  const findLoadingTypesIcon = () => wrapper.find('[data-testid="loading-types"]');

  const createComponent = ({ data = {}, props = {}, queryHandler = querySuccessHandler } = {}) => {
    fakeApollo = createMockApollo([[projectWorkItemTypesQuery, queryHandler]], resolvers);
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
      provide: {
        fullPath: 'full-path',
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

    it('does not add padding for content', () => {
      expect(findContent().classes('gl-px-5')).toBe(false);
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

    it('adds padding for content', () => {
      expect(findContent().classes('gl-px-5')).toBe(true);
    });
  });

  it('displays a loading icon inside dropdown when work items query is loading', () => {
    createComponent();

    expect(findLoadingTypesIcon().exists()).toBe(true);
  });

  it('displays an alert when work items query is rejected', async () => {
    createComponent({ queryHandler: jest.fn().mockRejectedValue('Houston, we have a problem') });
    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toContain('fetching work item types');
  });

  describe('when work item types are fetched', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('displays a list of work item types', () => {
      expect(findDropdownItems()).toHaveLength(2);
      expect(findDropdownItems().at(0).text()).toContain('Issue');
    });

    it('selects a work item type on click', async () => {
      expect(findDropdown().props('text')).toBe('Type');
      findDropdownItems().at(0).vm.$emit('click');
      await nextTick();

      expect(findDropdown().props('text')).toBe('Issue');
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
