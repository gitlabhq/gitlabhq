import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import ItemTitle from '~/work_items/components/item_title.vue';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import createWorkItemFromTaskMutation from '~/work_items/graphql/create_work_item_from_task.mutation.graphql';
import { projectWorkItemTypesQueryResponse, createWorkItemMutationResponse } from '../mock_data';

jest.mock('~/lib/utils/uuids', () => ({ uuids: () => ['testuuid'] }));

Vue.use(VueApollo);

describe('Create work item component', () => {
  let wrapper;
  let fakeApollo;

  const querySuccessHandler = jest.fn().mockResolvedValue(projectWorkItemTypesQueryResponse);
  const createWorkItemSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(ItemTitle);
  const findSelect = () => wrapper.findComponent(GlFormSelect);

  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findContent = () => wrapper.find('[data-testid="content"]');
  const findLoadingTypesIcon = () => wrapper.find('[data-testid="loading-types"]');

  const createComponent = ({
    data = {},
    props = {},
    queryHandler = querySuccessHandler,
    mutationHandler = createWorkItemSuccessHandler,
  } = {}) => {
    fakeApollo = createMockApollo(
      [
        [projectWorkItemTypesQuery, queryHandler],
        [createWorkItemMutation, mutationHandler],
        [createWorkItemFromTaskMutation, mutationHandler],
      ],
      {},
      { typePolicies: { Project: { merge: true } } },
    );
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

      expect(wrapper.vm.$router.push).toHaveBeenCalledWith({
        name: 'workItem',
        params: { id: '1' },
      });
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
      expect(findSelect().attributes('options').split(',')).toHaveLength(6);
    });

    it('selects a work item type on click', async () => {
      const mockId = 'work-item-1';
      findSelect().vm.$emit('input', mockId);
      await nextTick();
      expect(findSelect().attributes('value')).toBe(mockId);
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
    expect(findTitleInput().props('title')).toBe(initialTitle);
  });

  describe('when title input field has a text', () => {
    beforeEach(async () => {
      const mockTitle = 'Test title';
      createComponent();
      await waitForPromises();
      findTitleInput().vm.$emit('title-input', mockTitle);
    });

    it('renders a disabled Create button', () => {
      expect(findCreateButton().props('disabled')).toBe(true);
    });

    it('renders a non-disabled Create button when work item type is selected', async () => {
      findSelect().vm.$emit('input', 'work-item-1');
      await nextTick();
      expect(findCreateButton().props('disabled')).toBe(false);
    });
  });

  it('shows an alert on mutation error', async () => {
    createComponent({ mutationHandler: errorHandler });
    await waitForPromises();
    findTitleInput().vm.$emit('title-input', 'some title');
    findSelect().vm.$emit('input', 'work-item-1');
    wrapper.find('form').trigger('submit');
    await waitForPromises();

    expect(findAlert().text()).toBe(
      'Something went wrong when creating work item. Please try again.',
    );
  });
});
