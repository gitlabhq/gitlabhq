import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import WorkItemTitleWithEdit from '~/work_items/components/work_item_title_with_edit.vue';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '~/work_items/constants';
import groupWorkItemTypesQuery from '~/work_items/graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import {
  groupWorkItemTypesQueryResponse,
  projectWorkItemTypesQueryResponse,
  createWorkItemMutationResponse,
} from '../mock_data';

Vue.use(VueApollo);

describe('Create work item component', () => {
  let wrapper;
  let fakeApollo;

  const querySuccessHandler = jest.fn().mockResolvedValue(projectWorkItemTypesQueryResponse);
  const groupQuerySuccessHandler = jest.fn().mockResolvedValue(groupWorkItemTypesQueryResponse);
  const createWorkItemSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(WorkItemTitleWithEdit);
  const findSelect = () => wrapper.findComponent(GlFormSelect);

  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findLoadingTypesIcon = () => wrapper.find('[data-testid="loading-types"]');

  const createComponent = ({
    data = {},
    props = {},
    isGroup = false,
    query = projectWorkItemTypesQuery,
    queryHandler = querySuccessHandler,
    mutationHandler = createWorkItemSuccessHandler,
  } = {}) => {
    fakeApollo = createMockApollo(
      [
        [query, queryHandler],
        [createWorkItemMutation, mutationHandler],
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
      provide: {
        fullPath: 'full-path',
        isGroup,
      },
    });
  };

  it('does not render error by default', () => {
    createComponent();

    expect(findAlert().exists()).toBe(false);
  });

  it('renders a disabled Create button when title input is empty', () => {
    createComponent();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('emits event on Cancel button click', () => {
    createComponent();

    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted('cancel')).toEqual([[]]);
  });

  it('emits workItemCreated on successful mutation', async () => {
    createComponent();

    findTitleInput().vm.$emit('updateDraft', 'Test title');

    wrapper.find('form').trigger('submit');
    await waitForPromises();

    expect(wrapper.emitted('workItemCreated')).toEqual([
      [createWorkItemMutationResponse.data.workItemCreate.workItem],
    ]);
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

  it('displays a list of project work item types', async () => {
    createComponent({
      queryHandler: querySuccessHandler,
    });
    await waitForPromises();

    expect(findSelect().attributes('options').split(',')).toHaveLength(6);
  });

  it('fetches group work item types when isGroup is true', async () => {
    createComponent({
      isGroup: true,
      query: groupWorkItemTypesQuery,
      queryHandler: groupQuerySuccessHandler,
    });

    await waitForPromises();

    expect(groupQuerySuccessHandler).toHaveBeenCalled();
    expect(findSelect().exists()).toBe(false);
  });

  it('hides the select field if there is only a single type', async () => {
    createComponent({
      queryHandler: groupQuerySuccessHandler,
    });
    await waitForPromises();

    expect(findSelect().exists()).toBe(false);
  });

  it('filters types by workItemType', async () => {
    createComponent({
      props: {
        workItemType: WORK_ITEM_TYPE_ENUM_EPIC,
      },
    });

    await waitForPromises();

    expect(querySuccessHandler).toHaveBeenCalledWith({
      fullPath: 'full-path',
      name: WORK_ITEM_TYPE_ENUM_EPIC,
    });
  });

  it('selects a work item type on click', async () => {
    createComponent();
    await waitForPromises();

    const mockId = 'work-item-1';
    findSelect().vm.$emit('input', mockId);
    await nextTick();

    expect(findSelect().attributes('value')).toBe(mockId);
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
      findTitleInput().vm.$emit('updateDraft', mockTitle);
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
    findTitleInput().vm.$emit('updateDraft', 'some title');
    findSelect().vm.$emit('input', 'work-item-1');
    wrapper.find('form').trigger('submit');
    await waitForPromises();

    expect(findAlert().text()).toBe('Something went wrong when creating item. Please try again.');
  });
});
