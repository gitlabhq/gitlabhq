import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import namespaceWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/namespace_work_item_types.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '~/work_items/constants';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import { createWorkItemMutationResponse, createWorkItemQueryResponse } from '../mock_data';

const namespaceSingleWorkItemTypeQueryResponse = {
  data: {
    workspace: {
      ...namespaceWorkItemTypesQueryResponse.data.workspace,
      workItemTypes: {
        nodes: [namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes[0]],
      },
    },
  },
};

Vue.use(VueApollo);

describe('Create work item component', () => {
  let wrapper;
  let mockApollo;
  const workItemTypeEpicId = 'gid://gitlab/WorkItems::Type/8';

  const createWorkItemSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const workItemQuerySuccessHandler = jest.fn().mockResolvedValue(createWorkItemQueryResponse);
  const namespaceWorkItemTypesHandler = jest
    .fn()
    .mockResolvedValue(namespaceWorkItemTypesQueryResponse);
  const findFormTitle = () => wrapper.find('h1');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(WorkItemTitle);
  const findDescriptionWidget = () => wrapper.findComponent(WorkItemDescription);
  const findAssigneesWidget = () => wrapper.findComponent(WorkItemAssignees);
  const findLabelsWidget = () => wrapper.findComponent(WorkItemLabels);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findConfidentialCheckbox = () => wrapper.find('[data-testid="confidential-checkbox"]');
  const findCreateWorkItemView = () => wrapper.find('[data-testid="create-work-item-view"]');

  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');

  const createComponent = ({
    props = {},
    isGroup = false,
    mutationHandler = createWorkItemSuccessHandler,
    singleWorkItemType = false,
    workItemTypeName = WORK_ITEM_TYPE_ENUM_EPIC,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [workItemByIidQuery, workItemQuerySuccessHandler],
        [createWorkItemMutation, mutationHandler],
        [namespaceWorkItemTypesQuery, namespaceWorkItemTypesHandler],
      ],
      resolvers,
      { typePolicies: { Project: { merge: true } } },
    );

    const namespaceWorkItemTypeResponse = singleWorkItemType
      ? namespaceSingleWorkItemTypeQueryResponse
      : namespaceWorkItemTypesQueryResponse;
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: namespaceWorkItemTypesQuery,
      variables: { fullPath: 'full-path', name: workItemTypeName },
      data: namespaceWorkItemTypeResponse.data,
    });

    wrapper = shallowMount(CreateWorkItem, {
      apolloProvider: mockApollo,
      propsData: {
        workItemTypeName,
        ...props,
      },
      provide: {
        fullPath: 'full-path',
        isGroup,
        hasIssuableHealthStatusFeature: false,
      },
    });
  };

  const initialiseComponentAndSelectWorkItem = async ({
    mutationHandler = createWorkItemSuccessHandler,
  } = {}) => {
    createComponent({ mutationHandler });

    await waitForPromises();

    findSelect().vm.$emit('input', workItemTypeEpicId);
    await waitForPromises();
  };

  const updateWorkItemTitle = async (title = 'Test title') => {
    findTitleInput().vm.$emit('updateDraft', title);
    await nextTick();
    await waitForPromises();
  };

  const submitCreateForm = async () => {
    wrapper.find('form').trigger('submit');
    await waitForPromises();
  };

  const mockCurrentUser = {
    id: 1,
    name: 'Administrator',
    username: 'root',
    avatar_url: 'avatar/url',
  };

  beforeEach(() => {
    gon.current_user_id = mockCurrentUser.id;
    gon.current_user_fullname = mockCurrentUser.name;
    gon.current_username = mockCurrentUser.username;
    gon.current_user_avatar_url = mockCurrentUser.avatar_url;
  });

  describe('Default', () => {
    beforeEach(async () => {
      await initialiseComponentAndSelectWorkItem();
    });

    it('does not render error by default', () => {
      expect(findTitleInput().props('isValid')).toBe(true);
      expect(findAlert().exists()).toBe(false);
    });

    it('emits event on Cancel button click', () => {
      findCancelButton().vm.$emit('click');
      expect(wrapper.emitted('cancel')).toEqual([[]]);
    });
  });

  describe('When there is no work item type', () => {
    beforeEach(() => {
      createComponent({ workItemTypeName: null });
      return waitForPromises();
    });

    it('shows the select dropdown with the valid work item types', () => {
      expect(findSelect().exists()).toBe(true);
    });

    it('does not render the work item view', () => {
      expect(findCreateWorkItemView().exists()).toBe(false);
    });
  });

  describe('Work item types dropdown', () => {
    it('displays a list of namespace work item types', async () => {
      createComponent();
      await waitForPromises();

      // +1 for the "None" option
      const expectedOptions =
        namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.length + 1;
      expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
    });

    it('hides the select field if there is only a single type', async () => {
      createComponent({
        singleWorkItemType: true,
      });
      await waitForPromises();

      expect(findSelect().exists()).toBe(false);
    });

    it('selects a work item type on click', async () => {
      createComponent();
      await waitForPromises();

      const mockId = 'Issue';
      findSelect().vm.$emit('input', mockId);
      await nextTick();

      expect(findSelect().attributes('value')).toBe(mockId);
    });

    it('hides title if set', async () => {
      createComponent({
        props: { hideFormTitle: true },
      });

      await waitForPromises();

      expect(findFormTitle().exists()).toBe(false);
    });
  });

  describe('Create work item', () => {
    it('emits workItemCreated on successful mutation', async () => {
      await initialiseComponentAndSelectWorkItem();

      findTitleInput().vm.$emit('updateDraft', 'Test title');
      await waitForPromises();

      await submitCreateForm();

      expect(wrapper.emitted('workItemCreated')).toEqual([
        [createWorkItemMutationResponse.data.workItemCreate.workItem],
      ]);
    });

    it('emits workItemCreated for confidential work item', async () => {
      await initialiseComponentAndSelectWorkItem();

      findConfidentialCheckbox().vm.$emit('change', true);
      await updateWorkItemTitle();

      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          title: 'Test title',
          confidential: true,
        }),
      });
    });

    it('does not commit when title is empty', async () => {
      await initialiseComponentAndSelectWorkItem();

      await updateWorkItemTitle('');

      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(findTitleInput().props('isValid')).toBe(false);
      expect(wrapper.emitted('workItemCreated')).toEqual(undefined);
    });

    it('updates work item title on update mutation', async () => {
      await initialiseComponentAndSelectWorkItem();

      await updateWorkItemTitle();

      expect(findTitleInput().props('title')).toBe('Test title');
    });

    it('when title input field has a text renders Create button when work item type is selected', async () => {
      await initialiseComponentAndSelectWorkItem();
      await updateWorkItemTitle();

      expect(findCreateButton().props('disabled')).toBe(false);
    });

    it('shows an alert on mutation error', async () => {
      await initialiseComponentAndSelectWorkItem({ mutationHandler: errorHandler });

      await updateWorkItemTitle();

      await submitCreateForm();

      expect(findAlert().text()).toBe('Something went wrong when creating epic. Please try again.');
    });
  });

  describe('Create work item widgets for epic work item type', () => {
    beforeEach(async () => {
      await initialiseComponentAndSelectWorkItem();
    });

    it('renders the work item title widget', () => {
      expect(findTitleInput().exists()).toBe(true);
    });

    it('renders the work item description widget', () => {
      expect(findDescriptionWidget().exists()).toBe(true);
    });

    it('renders the work item assignees widget', () => {
      expect(findAssigneesWidget().exists()).toBe(true);
    });

    it('renders the work item labels widget', () => {
      expect(findLabelsWidget().exists()).toBe(true);
    });
  });
});
