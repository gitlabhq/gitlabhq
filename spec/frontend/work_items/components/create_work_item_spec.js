import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlFormSelect, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture } from 'helpers/fixtures';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { clearDraft, updateDraft } from '~/lib/utils/autosave';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemCrmContacts from '~/work_items/components/work_item_crm_contacts.vue';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemParent from '~/work_items/components/work_item_parent.vue';
import WorkItemProjectsListbox from '~/work_items/components/work_item_links/work_item_projects_listbox.vue';
import WorkItemNamespaceListbox from '~/work_items/components/shared/work_item_namespace_listbox.vue';
import TitleSuggestions from '~/issues/new/components/title_suggestions.vue';
import {
  CREATION_CONTEXT_LIST_ROUTE,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_NAME_REQUIREMENTS,
  WORK_ITEM_TYPE_NAME_TASK,
  WORK_ITEM_TYPE_NAME_TEST_CASE,
  WORK_ITEM_TYPE_NAME_TICKET,
} from '~/work_items/constants';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { updateDraftWorkItemType } from '~/work_items/utils';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import updateNewWorkItemMutation from '~/work_items/graphql/update_new_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  createWorkItemMutationResponse,
  createWorkItemMutationErrorResponse,
  createWorkItemQueryResponse,
  namespaceWorkItemTypesQueryResponse,
} from 'ee_else_ce_jest/work_items/mock_data';

jest.mock('~/alert');
jest.mock('~/work_items/graphql/cache_utils', () => ({
  setNewWorkItemCache: jest.fn(),
}));
jest.mock('~/work_items/utils', () => {
  return {
    ...jest.requireActual('~/work_items/utils'),
    updateDraftWorkItemType: jest.fn(),
  };
});
jest.mock('~/lib/utils/autosave', () => {
  return {
    ...jest.requireActual('~/lib/utils/autosave'),
    clearDraft: jest.fn(),
  };
});

Vue.use(VueApollo);

describe('Create work item component', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  const originalFeatures = gon.features;
  let wrapper;
  let mockApollo;

  useLocalStorageSpy();

  const createWorkItemSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const mutationErrorHandler = jest.fn().mockResolvedValue(createWorkItemMutationErrorResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');
  const workItemQuerySuccessHandler = jest.fn().mockResolvedValue(createWorkItemQueryResponse());
  const namespaceWorkItemTypes =
    namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes;
  const mockRelatedItem = {
    id: 'gid://gitlab/WorkItem/22',
    type: 'Issue',
    reference: 'full-path#22',
    webUrl: '/full-path/-/issues/22',
  };

  const findFormTitle = () => wrapper.find('h1');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(WorkItemTitle);
  const findDescriptionWidget = () => wrapper.findComponent(WorkItemDescription);
  const findAssigneesWidget = () => wrapper.findComponent(WorkItemAssignees);
  const findLabelsWidget = () => wrapper.findComponent(WorkItemLabels);
  const findCrmContactsWidget = () => wrapper.findComponent(WorkItemCrmContacts);
  const findMilestoneWidget = () => wrapper.findComponent(WorkItemMilestone);
  const findParentWidget = () => wrapper.findComponent(WorkItemParent);
  const findProjectsSelector = () => wrapper.findComponent(WorkItemProjectsListbox);
  const findGroupProjectSelector = () => wrapper.findComponent(WorkItemNamespaceListbox);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findTitleSuggestions = () => wrapper.findComponent(TitleSuggestions);
  const findConfidentialCheckbox = () => wrapper.findByTestId('confidential-checkbox');
  const findRelatesToCheckbox = () => wrapper.findByTestId('relates-to-checkbox');
  const findCreateWorkItemView = () => wrapper.findByTestId('create-work-item-view');
  const findFormButtons = () => wrapper.findByTestId('form-buttons');
  const findCreateButton = () => wrapper.findByTestId('create-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findResolveDiscussionSection = () => wrapper.findByTestId('work-item-resolve-discussion');
  const findResolveDiscussionLink = () =>
    wrapper.findByTestId('work-item-resolve-discussion').findComponent(GlLink);

  const createComponent = ({
    props = {},
    provide = {},
    mutationHandler = createWorkItemSuccessHandler,
    namespaceQueryResponse = namespaceWorkItemTypesQueryResponse,
    preselectedWorkItemType = WORK_ITEM_TYPE_NAME_EPIC,
    isGroupWorkItem = false,
    fullPath = 'full-path',
  } = {}) => {
    const namespaceResponseCopy = cloneDeep(namespaceQueryResponse);
    namespaceResponseCopy.data.workspace.id = 'gid://gitlab/Group/33';
    const namespaceResponse = isGroupWorkItem ? namespaceResponseCopy : namespaceQueryResponse;

    const namespaceWorkItemTypesHandler = jest.fn().mockResolvedValue(namespaceResponse);

    mockApollo = createMockApollo(
      [
        [workItemByIidQuery, workItemQuerySuccessHandler],
        [createWorkItemMutation, mutationHandler],
        [namespaceWorkItemTypesQuery, namespaceWorkItemTypesHandler],
      ],
      resolvers,
    );

    wrapper = shallowMountExtended(CreateWorkItem, {
      apolloProvider: mockApollo,
      propsData: {
        creationContext: CREATION_CONTEXT_LIST_ROUTE,
        fullPath,
        projectNamespaceFullPath: fullPath,
        preselectedWorkItemType,
        ...props,
      },
      provide: {
        groupPath: 'group-path',
        hasIssuableHealthStatusFeature: false,
        hasIterationsFeature: true,
        hasIssueWeightsFeature: false,
        hasStatusFeature: false,
        issuesSettings: '/groups/twitter/-/settings/issues',
        ...provide,
      },
      stubs: {
        PageHeading,
        GlSprintf,
      },
    });
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
    gon.features = {};
  });

  afterAll(() => {
    gon.features = originalFeatures;
  });

  describe('Default', () => {
    beforeEach(async () => {
      createComponent({
        props: {
          relatedItem: mockRelatedItem,
        },
      });
      await waitForPromises();
    });

    it('does not render error by default', () => {
      expect(findTitleInput().props('isValid')).toBe(true);
      expect(findAlert().exists()).toBe(false);
    });

    it('calls `updateNewWorkItemMutation` mutation when any widget emits `updateWidgetDraft` event', () => {
      jest.spyOn(mockApollo.defaultClient, 'mutate');
      const mockInput = {
        assignees: [
          {
            __typename: 'CurrentUser',
            id: 'gid://gitlab/User/1',
            name: 'Administrator',
            username: 'root',
            webUrl: 'http://127.0.0.1:3000/root',
            webPath: '/root',
          },
        ],
      };

      findAssigneesWidget().vm.$emit('updateWidgetDraft', mockInput);
      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: updateNewWorkItemMutation,
        variables: {
          input: {
            fullPath: 'full-path',
            context: CREATION_CONTEXT_LIST_ROUTE,
            workItemType: 'Epic',
            relatedItemId: mockRelatedItem.id,
            ...mockInput,
          },
        },
      });
    });

    it('emits "confirmCancel" event on Cancel button click if form is filled', async () => {
      await updateWorkItemTitle();
      findCancelButton().vm.$emit('click');

      expect(wrapper.emitted('confirmCancel')).toEqual([[]]);
    });

    it('emits "discardDraft" event on Cancel button click if form is filled', () => {
      findCancelButton().vm.$emit('click');

      expect(wrapper.emitted('discardDraft')).toEqual([[]]);
    });

    it.each`
      scenario                               | fullPath                               | expectedGroupPath
      ${'group-path'}                        | ${'group-path'}                        | ${'group-path'}
      ${'group-path/sub-group-path'}         | ${'group-path/sub-group-path'}         | ${'group-path'}
      ${'group-path/project'}                | ${'group-path/project'}                | ${'group-path'}
      ${'group-path/sub-group-path/project'} | ${'group-path/sub-group-path/project'} | ${'group-path/sub-group-path'}
    `(
      'passes correct group path "$expectedGroupPath" for fullpath $scenario',
      async ({ fullPath, expectedGroupPath }) => {
        createComponent({
          fullPath,
        });

        await waitForPromises();

        expect(findParentWidget().props().groupPath).toBe(expectedGroupPath);
      },
    );
  });

  describe('Cache clearing', () => {
    it('Default', async () => {
      createComponent();
      await waitForPromises();
      const typeSpecificAutosaveKey = 'new-full-path-list-route-epic-draft';
      const sharedWidgetsAutosaveKey = 'new-full-path-list-route-widgets-draft';

      findCancelButton().vm.$emit('click');
      await nextTick();

      expect(clearDraft).toHaveBeenCalledTimes(2);
      expect(clearDraft).toHaveBeenNthCalledWith(1, typeSpecificAutosaveKey);
      expect(clearDraft).toHaveBeenNthCalledWith(2, sharedWidgetsAutosaveKey);
      expect(setNewWorkItemCache).toHaveBeenCalled();
    });

    it.each`
      workItemType
      ${WORK_ITEM_TYPE_NAME_EPIC}
      ${WORK_ITEM_TYPE_NAME_INCIDENT}
      ${WORK_ITEM_TYPE_NAME_ISSUE}
      ${WORK_ITEM_TYPE_NAME_KEY_RESULT}
      ${WORK_ITEM_TYPE_NAME_OBJECTIVE}
      ${WORK_ITEM_TYPE_NAME_REQUIREMENTS}
      ${WORK_ITEM_TYPE_NAME_TASK}
      ${WORK_ITEM_TYPE_NAME_TEST_CASE}
      ${WORK_ITEM_TYPE_NAME_TICKET}
    `(
      'Clears cache on cancel for workItemType=$workItemType with the correct data',
      async ({ workItemType }) => {
        const expectedWorkItemTypeData = namespaceWorkItemTypes.find(
          ({ name }) => name === workItemType,
        );
        createComponent({
          props: {
            preselectedWorkItemType: workItemType,
            relatedItem: mockRelatedItem,
          },
        });
        await waitForPromises();

        findCancelButton().vm.$emit('click');
        await nextTick();

        expect(setNewWorkItemCache).toHaveBeenCalledWith({
          fullPath: 'full-path',
          context: CREATION_CONTEXT_LIST_ROUTE,
          widgetDefinitions: expect.any(Array),
          workItemType: expectedWorkItemTypeData.name,
          workItemTypeId: expectedWorkItemTypeData.id,
          workItemTypeIconName: expectedWorkItemTypeData.iconName,
          relatedItemId: mockRelatedItem.id,
        });
      },
    );
  });

  describe('When there is no work item type', () => {
    beforeEach(() => {
      createComponent({ props: { preselectedWorkItemType: null } });
      return waitForPromises();
    });

    it('shows the select dropdown with the valid work item types', () => {
      expect(findSelect().exists()).toBe(true);
    });

    it('does not render the work item view', () => {
      expect(findCreateWorkItemView().exists()).toBe(false);
    });
  });

  describe('project selector', () => {
    it.each([true, false])(
      'renders based on value of showProjectSelector prop',
      async (showProjectSelector) => {
        createComponent({ props: { showProjectSelector } });
        await waitForPromises();

        expect(findProjectsSelector().exists()).toBe(showProjectSelector);
      },
    );

    it('defaults the selected project to the injected `fullPath` value', async () => {
      const namespaceFullName = 'GitLab.org / GitLab';
      createComponent({
        props: { showProjectSelector: true, namespaceFullName },
      });
      await waitForPromises();

      expect(findProjectsSelector().props('currentProjectName')).toBe(namespaceFullName);
      expect(findProjectsSelector().props('selectedProjectFullPath')).toBe('full-path');
    });
  });

  describe('Group/project selector', () => {
    it('renders with the current namespace selected by default', async () => {
      createComponent({
        props: { isGroup: true },
        provide: { workItemPlanningViewEnabled: true },
      });
      await waitForPromises();

      expect(findGroupProjectSelector().exists()).toBe(true);
      expect(findGroupProjectSelector().props('fullPath')).toBe('full-path');
    });

    it.each`
      scenario                   | isGroup  | fromGlobalMenu | isEpicsList | workItemPlanningViewEnabled | expected
      ${'group list page'}       | ${true}  | ${false}       | ${false}    | ${true}                     | ${true}
      ${'project global menu'}   | ${false} | ${true}        | ${false}    | ${true}                     | ${true}
      ${'legacy epics list'}     | ${true}  | ${false}       | ${true}     | ${false}                    | ${false}
      ${'disabled feature flag'} | ${true}  | ${false}       | ${false}    | ${false}                    | ${false}
    `(
      '$scenario shows selector: $expected',
      async ({ isGroup, fromGlobalMenu, isEpicsList, workItemPlanningViewEnabled, expected }) => {
        createComponent({
          props: { isGroup, fromGlobalMenu, isEpicsList },
          provide: { workItemPlanningViewEnabled },
        });

        await waitForPromises();
        expect(findGroupProjectSelector().exists()).toBe(expected);
      },
    );
  });

  describe('Work item types dropdown', () => {
    it('renders with loading icon when namespaceWorkItemTypes query is loading', async () => {
      createComponent({ props: { preselectedWorkItemType: null, showProjectSelector: true } });
      await waitForPromises();

      findProjectsSelector().vm.$emit('selectProject', 'fullPath');
      await nextTick();

      expect(findSelect().attributes('disabled')).not.toBeUndefined();
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('displays a list of work item types including "Select type" option when preselectedWorkItemType is not provided', async () => {
      createComponent({ props: { preselectedWorkItemType: null } });
      await waitForPromises();
      // +1 for the "Select type" option
      const expectedOptions = namespaceWorkItemTypes.length + 1;

      expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
    });

    it('hides the type selector if preselectedWorkItemType is provided', async () => {
      createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_EPIC } });
      await waitForPromises();

      expect(findSelect().exists()).toBe(false);
    });

    it('shows the type selector when alwaysShowWorkItemTypeSelect=true even if preselectedWorkItemType is provided', async () => {
      createComponent({
        props: {
          preselectedWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
          alwaysShowWorkItemTypeSelect: true,
        },
      });
      await waitForPromises();

      expect(findSelect().exists()).toBe(true);
    });

    it('does not show the "Select type" option when preselectedWorkItemType is provided and alwaysShowWorkItemTypeSelect=true', async () => {
      createComponent({
        props: {
          preselectedWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
          alwaysShowWorkItemTypeSelect: true,
        },
      });
      await waitForPromises();

      expect(findSelect().attributes('options').split(',')).toHaveLength(
        namespaceWorkItemTypes.length,
      );
    });

    it('restricts the type selector to types provided by allowedWorkItemTypes', async () => {
      const allowedWorkItemTypes = [
        WORK_ITEM_TYPE_NAME_INCIDENT,
        WORK_ITEM_TYPE_NAME_ISSUE,
        WORK_ITEM_TYPE_NAME_TASK,
      ];
      createComponent({ props: { preselectedWorkItemType: null, allowedWorkItemTypes } });
      await waitForPromises();
      // +1 for the "Select type" option
      const expectedOptions = allowedWorkItemTypes.length + 1;

      expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
    });

    it('selects a work item type on click', async () => {
      createComponent({ props: { preselectedWorkItemType: null } });
      await waitForPromises();
      const mockId = 'Issue';

      findSelect().vm.$emit('input', mockId);
      await nextTick();

      expect(findSelect().attributes('value')).toBe(mockId);
    });

    it('sets new work item cache and emits changeType on select', async () => {
      createComponent({ props: { preselectedWorkItemType: null, relatedItem: mockRelatedItem } });
      await waitForPromises();
      const mockId = 'Issue';

      findSelect().vm.$emit('change', mockId);
      await nextTick();

      expect(setNewWorkItemCache).toHaveBeenCalledWith({
        fullPath: 'full-path',
        context: CREATION_CONTEXT_LIST_ROUTE,
        widgetDefinitions: expect.any(Array),
        workItemType: mockId,
        workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
        workItemTypeIconName: 'issue-type-issue',
        relatedItemId: mockRelatedItem.id,
      });

      expect(wrapper.emitted('changeType')).toBeDefined();
    });

    it('sets selected work item type in localStorage draft', async () => {
      createComponent({ props: { preselectedWorkItemType: null, relatedItem: mockRelatedItem } });
      await waitForPromises();
      const mockId = 'Issue';

      findSelect().vm.$emit('change', mockId);
      await nextTick();

      expect(updateDraftWorkItemType).toHaveBeenCalledWith({
        fullPath: 'full-path',
        context: CREATION_CONTEXT_LIST_ROUTE,
        relatedItemId: mockRelatedItem.id,
        workItemType: {
          id: 'gid://gitlab/WorkItems::Type/1',
          name: mockId,
          iconName: 'issue-type-issue',
        },
      });
    });

    it('hides title if set', async () => {
      createComponent({ props: { hideFormTitle: true } });
      await waitForPromises();

      expect(findFormTitle().exists()).toBe(false);
    });

    it('filters work item type based on route parameter', async () => {
      createComponent();
      await waitForPromises();

      expect(findSelect().exists()).toBe(false);
      expect(findFormTitle().text()).toBe('New epic');
    });
  });

  describe('Create work item', () => {
    it('emits workItemCreated on successful mutation', async () => {
      setWindowLocation(
        '?discussion_to_resolve=f20989738bfe845f73a77a7109b1588852901befJD9I3FGU&merge_request_id=13',
      );
      const workItem = { ...createWorkItemMutationResponse.data.workItemCreate.workItem };
      // there is a mismatch between the response and the expected workItem object between CE and EE fixture
      // so we need to remove the `promotedToEpicUrl` property from the expected workItem object
      delete workItem.promotedToEpicUrl;

      createComponent();
      await waitForPromises();

      findTitleInput().vm.$emit('updateDraft', 'Test title');
      await waitForPromises();
      await submitCreateForm();

      expect(wrapper.emitted('workItemCreated')).toEqual([
        [
          {
            workItem: expect.objectContaining(workItem),
            numberOfDiscussionsResolved: '1',
          },
        ],
      ]);
    });

    it('clears autosave draft on successful mutation', async () => {
      const typeSpecificAutosaveKey = 'new-full-path-list-route-related-id-22-epic-draft';
      const sharedWidgetsAutosaveKey = 'new-full-path-list-route-related-id-22-widgets-draft';
      updateDraft(typeSpecificAutosaveKey, JSON.stringify({ foo: 'bar' }));
      updateDraft(sharedWidgetsAutosaveKey, JSON.stringify({ foo: 'bar' }));
      createComponent({
        props: {
          relatedItem: mockRelatedItem,
        },
      });
      await waitForPromises();

      findTitleInput().vm.$emit('updateDraft', 'Test title');
      await waitForPromises();
      await submitCreateForm();

      expect(clearDraft).toHaveBeenCalledTimes(2);
      expect(clearDraft).toHaveBeenNthCalledWith(1, typeSpecificAutosaveKey);
      expect(clearDraft).toHaveBeenNthCalledWith(2, sharedWidgetsAutosaveKey);
    });

    it('emits workItemCreated for confidential work item', async () => {
      createComponent();
      await waitForPromises();

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

    it('creates work item with parent when parentId exists', async () => {
      const parentId = 'gid://gitlab/WorkItem/456';
      createComponent({ props: { parentId } });
      await waitForPromises();

      await updateWorkItemTitle();
      wrapper.find('form').trigger('submit');

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          hierarchyWidget: { parentId },
        }),
      });
    });

    it('creates work item within a specific namespace when project is selected', async () => {
      const fullPath = 'chosen/full/path';
      createComponent({ props: { showProjectSelector: true } });
      await waitForPromises();

      findProjectsSelector().vm.$emit('selectProject', fullPath);
      await updateWorkItemTitle();
      wrapper.find('form').trigger('submit');

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          namespacePath: fullPath,
        }),
      });
    });

    it('correct fullPath is provided to components when project is selected', async () => {
      const fullPath = 'chosen/full/path';
      createComponent({ props: { showProjectSelector: true } });
      await waitForPromises();

      expect(findAssigneesWidget().props('fullPath')).toBe('full-path');

      findProjectsSelector().vm.$emit('selectProject', fullPath);

      await nextTick();

      expect(findAssigneesWidget().props('fullPath')).toBe(fullPath);
    });

    it('does not commit when title is empty', async () => {
      createComponent();
      await waitForPromises();

      await updateWorkItemTitle('');
      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(findTitleInput().props('isValid')).toBe(false);
      expect(wrapper.emitted('workItemCreated')).toBeUndefined();
    });

    it('updates work item title on update mutation', async () => {
      createComponent();
      await waitForPromises();

      await updateWorkItemTitle();

      expect(findTitleInput().props('title')).toBe('Test title');
    });

    it('when title input field has a text renders Create button when work item type is selected', async () => {
      createComponent();
      await waitForPromises();

      await updateWorkItemTitle();

      expect(findCreateButton().props('disabled')).toBe(false);
    });

    it('when title input text is deleted after typed, title is not valid anymore to submit', async () => {
      createComponent();
      await waitForPromises();

      await updateWorkItemTitle();

      expect(findTitleInput().props('title')).toBe('Test title');

      await updateWorkItemTitle('');
      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(findTitleInput().props('title')).toBe('');
      expect(findTitleInput().props('isValid')).toBe(false);
      expect(wrapper.emitted('workItemCreated')).toBeUndefined();
    });

    it('shows an alert on mutation error', async () => {
      createComponent({ mutationHandler: errorHandler });
      await waitForPromises();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(findAlert().text()).toBe('Something went wrong when creating epic. Please try again.');
    });

    it('shows a page alert on user-facing mutation error', async () => {
      createComponent({ mutationHandler: mutationErrorHandler });
      await waitForPromises();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: ['an error'],
        message: 'an error',
      });
    });
  });

  describe('Create work item widgets for epic work item type', () => {
    describe('default', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
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

      it('renders the work item CRM contacts widget', () => {
        expect(findCrmContactsWidget().exists()).toBe(true);
      });
    });

    it('uses the description prop as the initial description value when defined', async () => {
      const description = 'i am a description';
      createComponent({ props: { description } });
      await waitForPromises();

      expect(findDescriptionWidget().props('description')).toBe(description);
    });

    it('uses the title prop as the initial title value when defined', async () => {
      const title = 'i am a title';
      createComponent({ props: { title } });
      await waitForPromises();

      expect(findTitleInput().props('title')).toBe(title);
    });
  });

  describe('Create work item widgets for Issue work item type', () => {
    describe('default', () => {
      beforeEach(async () => {
        createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE } });
        await waitForPromises();
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

      it('renders the work item CRM contacts widget', () => {
        expect(findCrmContactsWidget().exists()).toBe(true);
      });

      it('renders the work item milestone widget', () => {
        expect(findMilestoneWidget().exists()).toBe(true);
      });
    });
  });

  describe('Create work item widgets for Incident work item type', () => {
    describe('default', () => {
      beforeEach(async () => {
        createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_INCIDENT } });
        await waitForPromises();
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

      it('renders the work item CRM contacts widget', () => {
        expect(findCrmContactsWidget().exists()).toBe(true);
      });

      it('renders the work item milestone widget', () => {
        expect(findMilestoneWidget().exists()).toBe(true);
      });

      it('does not renders the work item parent widget', () => {
        expect(findParentWidget().exists()).toBe(false);
      });
    });
  });

  describe('confidentiality checkbox', () => {
    it('is checked when parameter issue[confidential]=true', async () => {
      setWindowLocation('?issue[confidential]=true');
      createComponent();
      await waitForPromises();

      expect(findConfidentialCheckbox().attributes('checked')).toBe('true');
    });

    it('is not checked when parameter issue[confidential]!=true', async () => {
      setWindowLocation('?issue[confidential]=tru');
      createComponent();
      await waitForPromises();

      expect(findConfidentialCheckbox().attributes('checked')).toBeUndefined();
    });

    it('renders confidentiality checkbox for a group', async () => {
      createComponent({
        props: {
          isGroup: true,
        },
      });

      await waitForPromises();

      const confidentialCheckbox = findConfidentialCheckbox();

      expect(confidentialCheckbox.text()).toBe(
        'Turn on confidentiality: Limit visibility to group members with at least the Planner role.',
      );
    });

    it('renders confidentiality checkbox for a project', async () => {
      createComponent();

      await waitForPromises();

      const confidentialCheckbox = findConfidentialCheckbox();

      expect(confidentialCheckbox.text()).toBe(
        'Turn on confidentiality: Limit visibility to project members with at least the Planner role.',
      );
    });
  });

  describe('With related item', () => {
    const id = 'gid://gitlab/WorkItem/1';
    const type = 'Epic';
    const reference = 'related-full-path#1';
    const webUrl = 'web/url';

    beforeEach(async () => {
      createComponent({
        props: { relatedItem: { id, type, reference, webUrl }, showProjectSelector: true },
      });
      await waitForPromises();
    });

    it('renders the correct text for the checkbox', () => {
      expect(findRelatesToCheckbox().text()).toMatchInterpolatedText(
        'Mark this item as related to: epic #1',
      );
    });

    it('renders link within checkbox text', () => {
      const link = findRelatesToCheckbox().findComponent(GlLink);

      expect(link.text()).toBe('#1');
      expect(link.attributes('href')).toBe('web/url');
    });

    it('provides the related item fullPath to the project listbox', () => {
      const listbox = findProjectsSelector();

      expect(listbox.props('selectedProjectFullPath')).toBe('related-full-path');
    });

    it('provides the related item fullPath to the widget components', () => {
      const assigneesWidget = findAssigneesWidget();

      expect(assigneesWidget.props('fullPath')).toBe('related-full-path');
    });

    it('includes the related item in the create work item request', async () => {
      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          linkedItemsWidget: {
            workItemsIds: [id],
          },
        }),
      });
    });

    it('does not include the related item in the create work item request if the checkbox is unchecked', async () => {
      await updateWorkItemTitle();
      findRelatesToCheckbox().vm.$emit('input', false);
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).not.toHaveBeenCalledWith({
        input: expect.objectContaining({
          linkedItemsWidget: {
            workItemsIds: [id],
          },
        }),
      });
    });
  });

  describe('form buttons', () => {
    it('shows buttons on right and sticky when isModal', async () => {
      createComponent({ props: { isModal: true } });
      await waitForPromises();

      expect(findFormButtons().classes('gl-sticky')).toBe(true);
      expect(findFormButtons().classes('gl-justify-between')).toBe(true);
      expect(findFormButtons().findAllComponents(GlButton).at(0).text()).toBe('Cancel');
      expect(findFormButtons().findAllComponents(GlButton).at(1).text()).toBe('Create epic');
    });

    it('shows buttons on left and sticky when not isModal', async () => {
      createComponent({ props: { isModal: false } });
      await waitForPromises();

      expect(findFormButtons().classes('gl-sticky')).toBe(true);
      expect(findFormButtons().classes('gl-justify-between')).toBe(true);
      expect(findFormButtons().findAllComponents(GlButton).at(0).text()).toBe('Create epic');
      expect(findFormButtons().findAllComponents(GlButton).at(1).text()).toBe('Cancel');
    });

    it('shows contribution guidelines link when contributing.md exists', async () => {
      createComponent({ provide: { contributionGuidePath: 'contribution/guide/path' } });
      await waitForPromises();

      expect(findFormButtons().findComponent(GlLink).text()).toBe('contribution guidelines');
      expect(findFormButtons().findComponent(GlLink).attributes('href')).toBe(
        'contribution/guide/path',
      );
    });

    it('does not show contribution guidelines link when contributing.md does not exist', async () => {
      createComponent({ provide: { contributionGuidePath: undefined } });
      await waitForPromises();

      expect(findFormButtons().findComponent(GlLink).exists()).toBe(false);
    });
  });

  describe('Keyboard submit events', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      await updateWorkItemTitle();
    });

    it('should call handleKeydown method when keydown event is triggered with CTRL', () => {
      const event = new KeyboardEvent('keydown', { key: 'Enter', ctrlKey: true });
      document.dispatchEvent(event);

      expect(createWorkItemSuccessHandler).toHaveBeenCalled();
    });

    it('should call handleKeydown method when keydown event is triggered with CMD', () => {
      const event = new KeyboardEvent('keydown', { key: 'Enter', metaKey: true });
      document.dispatchEvent(event);

      expect(createWorkItemSuccessHandler).toHaveBeenCalled();
    });
  });

  it('renders work item title suggestions below work item title', async () => {
    createComponent();
    await waitForPromises();

    await updateWorkItemTitle();

    expect(findTitleSuggestions().props()).toStrictEqual({
      projectPath: 'full-path',
      search: 'Test title',
      helpText: 'These existing items have a similar title and may represent potential duplicates.',
      title: 'Similar items',
    });
  });

  it('does not show work item widgets when userPermissions.setNewWorkItemMetadata is false', async () => {
    const namespaceQueryResponse = {
      data: {
        workspace: {
          ...namespaceWorkItemTypesQueryResponse.data.workspace,
          userPermissions: {
            setNewWorkItemMetadata: false,
          },
        },
      },
    };

    createComponent({ namespaceQueryResponse });
    await waitForPromises();

    const widgetsContainer = wrapper.findByTestId('work-item-overview-right-sidebar');
    expect(widgetsContainer.exists()).toBe(true);
    expect(widgetsContainer.find('strong').text()).toContain('Limited access');
    expect(widgetsContainer.find('div').text()).toContain('Only project members can add metadata.');
  });

  describe('title and description query parameters', () => {
    it('saves to the cache when the backend provides them', async () => {
      setHTMLFixture(`
        <div class="new-issue-params hidden">
          <div class="params-title">
            i am a title
          </div>
          <div class="params-description">
            i
            am
            a
            description!
          </div>
          <div class="params-add-related-issue">
            234
          </div>
          <div class="params-discussion-to-resolve">

          </div>
        </div>`);
      createComponent({
        props: {
          relatedItem: mockRelatedItem,
        },
      });
      await waitForPromises();

      expect(setNewWorkItemCache).toHaveBeenCalledWith({
        fullPath: expect.anything(),
        context: CREATION_CONTEXT_LIST_ROUTE,
        widgetDefinitions: expect.anything(),
        workItemType: expect.anything(),
        workItemTypeId: expect.anything(),
        workItemTypeIconName: expect.anything(),
        workItemTitle: 'i am a title',
        workItemDescription: `i
            am
            a
            description!`,
        confidential: false,
        relatedItemId: mockRelatedItem.id,
      });
    });
  });

  describe('New work item to resolve threads', () => {
    it('when not resolving any thread, does not pass resolve params to mutation', async () => {
      createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE } });
      await waitForPromises();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).not.toHaveBeenCalledWith({
        input: expect.objectContaining({
          discussionsToResolve: null,
        }),
      });
    });

    it('when resolving all threads in a merge request', async () => {
      setWindowLocation(
        '?discussion_to_resolve=13&merge_request_to_resolve_discussions_of=112&merge_request_id=13',
      );

      createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE } });
      await waitForPromises();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          discussionsToResolve: {
            discussionId: '13',
            noteableId: 'gid://gitlab/MergeRequest/13',
          },
        }),
      });
    });

    describe('when resolving one thread in a merge request', () => {
      beforeEach(async () => {
        setHTMLFixture(`
        <div class="new-issue-params hidden">
          <div class="params-title">
            Follow-up from "Necessitatibus delectus ex animi consequatur facere ipsum quaerat iusto veniam architecto."
          </div>
          <div class="params-description">
            The following discussion from !1 should be addressed:

            - [ ] @marlen started a [discussion](http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/1#note_1224):  (+1 comment)

                &gt; Quis nihil est molestias nemo rerum aspernatur.
          </div>
          <div class="params-add-related-issue">

          </div>
          <div class="params-discussion-to-resolve">
            <a href="http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/1#note_1224">!1 (discussion 1224)</a>
          </div>
        </div>`);
        setWindowLocation(
          '?discussion_to_resolve=13&merge_request_to_resolve_discussions_of=112&merge_request_id=13',
        );
        createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE } });
        await waitForPromises();
      });

      it('renders text', () => {
        expect(findResolveDiscussionSection().text()).toMatchInterpolatedText(
          'Creating this issue will resolve the thread in !1 (discussion 1224)',
        );
      });

      it('renders "resolve the thread" information', () => {
        expect(findResolveDiscussionLink().text()).toBe('!1 (discussion 1224)');
        expect(findResolveDiscussionLink().props('href')).toBe(
          'http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/1#note_1224',
        );
      });

      it('calls mutation', async () => {
        await updateWorkItemTitle();
        await submitCreateForm();

        expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
          input: expect.objectContaining({
            discussionsToResolve: {
              discussionId: '13',
              noteableId: 'gid://gitlab/MergeRequest/13',
            },
          }),
        });
      });
    });
  });
});
