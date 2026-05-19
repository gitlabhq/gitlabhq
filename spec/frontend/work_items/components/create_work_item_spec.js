import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlFormSelect, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { cloneDeep } from 'lodash-es';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture } from 'helpers/fixtures';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { createControlledMockApollo } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { clearDraft, updateDraft } from '~/lib/utils/autosave';
import WorkItemDates from 'ee_else_ce/work_items/components/work_item_dates.vue';
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
import TitleSuggestions from '~/work_items/components/title_suggestions.vue';
import {
  CREATION_CONTEXT_DESCRIPTION_CHECKLIST,
  CREATION_CONTEXT_LIST_ROUTE,
  CREATION_CONTEXT_RELATED_ITEM,
  CREATION_CONTEXT_SUPER_SIDEBAR,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_NAME_REQUIREMENTS,
  WORK_ITEM_TYPE_NAME_TASK,
  WORK_ITEM_TYPE_NAME_TEST_CASE,
  WORK_ITEM_TYPE_NAME_TICKET,
  WORK_ITEM_CREATE_SOURCES,
} from '~/work_items/constants';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { updateDraftWorkItemType } from '~/work_items/utils';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import updateNewWorkItemMutation from '~/work_items/graphql/update_new_work_item.mutation.graphql';
import workItemTypesConfigurationQuery from '~/work_items/graphql/work_item_types_configuration.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  createWorkItemMutationResponse,
  createWorkItemMutationErrorResponse,
  createWorkItemQueryResponse,
  createWorkItemQueryResponseWithFeatures,
  namespaceWorkItemTypesQueryResponse,
  mockWorkItemTypesConfigurationResponse,
} from 'ee_else_ce_jest/work_items/mock_data';

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
  let apolloProvider;
  let resolveMutation;
  let resolveAll;

  useLocalStorageSpy();

  const createWorkItemSuccessHandler = jest.fn().mockReturnValue(createWorkItemMutationResponse);
  const mutationErrorHandler = () => createWorkItemMutationErrorResponse;
  const workItemQuerySuccessHandler = () => createWorkItemQueryResponse();
  const namespaceWorkItemTypes =
    namespaceWorkItemTypesQueryResponse.data.namespace.workItemTypes.nodes;
  const mockRelatedItem = {
    id: 'gid://gitlab/WorkItem/22',
    type: 'Issue',
    reference: 'full-path#22',
    webUrl: '/full-path/-/issues/22',
  };
  const workItemTypesWithConfiguration =
    mockWorkItemTypesConfigurationResponse.data.namespace.workItemTypes.nodes;

  let namespaceWorkItemTypesHandler;
  let workItemTypesConfigurationHandler;

  const findFormTitle = () => wrapper.find('h1');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(WorkItemTitle);
  const findDatesWidget = () => wrapper.findComponent(WorkItemDates);
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
    namespaceResponseCopy.data.namespace.id = 'gid://gitlab/Group/33';
    const namespaceResponse = isGroupWorkItem ? namespaceResponseCopy : namespaceQueryResponse;

    namespaceWorkItemTypesHandler = jest.fn().mockReturnValue(namespaceResponse);
    workItemTypesConfigurationHandler = jest
      .fn()
      .mockResolvedValue(mockWorkItemTypesConfigurationResponse);

    const mockResult = createControlledMockApollo(
      [
        [workItemByIidQuery, workItemQuerySuccessHandler],
        [createWorkItemMutation, mutationHandler],
        [namespaceWorkItemTypesQuery, namespaceWorkItemTypesHandler],
        [workItemTypesConfigurationQuery, workItemTypesConfigurationHandler],
      ],
      resolvers,
    );

    ({ apolloProvider, resolveMutation, resolveAll } = mockResult);

    wrapper = shallowMountExtended(CreateWorkItem, {
      apolloProvider: mockResult.apolloProvider,
      propsData: {
        creationContext: CREATION_CONTEXT_LIST_ROUTE,
        fullPath,
        projectNamespaceFullPath: fullPath,
        preselectedWorkItemType,
        ...props,
      },
      provide: {
        groupPath: 'group-path',
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
    await resolveMutation(createWorkItemMutation);
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
      await resolveAll();
      await nextTick();
    });

    it('does not render error by default', () => {
      expect(findTitleInput().props('isValid')).toBe(true);
      expect(findAlert().exists()).toBe(false);
    });

    it('calls `updateNewWorkItemMutation` mutation when any widget emits `updateWidgetDraft` event', () => {
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
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
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: updateNewWorkItemMutation,
        variables: {
          input: {
            useWorkItemFeatures: false,
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

        await resolveAll();

        expect(findParentWidget().props().groupPath).toBe(expectedGroupPath);
      },
    );
  });

  describe('Cache clearing', () => {
    it('Default', async () => {
      createComponent();
      await resolveAll();
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
        await resolveAll();

        findCancelButton().vm.$emit('click');
        await nextTick();

        expect(setNewWorkItemCache).toHaveBeenCalledWith(
          expect.objectContaining({
            fullPath: 'full-path',
            context: CREATION_CONTEXT_LIST_ROUTE,
            widgetDefinitions: expect.any(Array),
            workItemType: expectedWorkItemTypeData.name,
            workItemTypeId: expectedWorkItemTypeData.id,
            workItemTypeIconName: expectedWorkItemTypeData.iconName,
            relatedItemId: mockRelatedItem.id,
          }),
        );
      },
    );
  });

  describe('When there is no work item type', () => {
    beforeEach(async () => {
      createComponent({ props: { preselectedWorkItemType: null } });
      await resolveAll();
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
        await resolveAll();

        expect(findProjectsSelector().exists()).toBe(showProjectSelector);
      },
    );

    it('defaults the selected project to the injected `fullPath` value', async () => {
      const namespaceFullName = 'GitLab.org / GitLab';
      createComponent({
        props: { showProjectSelector: true, namespaceFullName },
      });
      await resolveAll();

      expect(findProjectsSelector().props('currentProjectName')).toBe(namespaceFullName);
      expect(findProjectsSelector().props('selectedProjectFullPath')).toBe('full-path');
    });
  });

  describe('Group/project selector', () => {
    it('renders with the current namespace selected by default', async () => {
      createComponent({
        props: { isGroup: true },
        provide: { hasEpicsFeature: true },
      });
      await resolveAll();

      expect(findGroupProjectSelector().exists()).toBe(true);
      expect(findGroupProjectSelector().props('fullPath')).toBe('full-path');
    });

    it.each`
      scenario                 | isGroup  | fromGlobalMenu | hasEpicsFeature | expected
      ${'group list page'}     | ${true}  | ${false}       | ${true}         | ${true}
      ${'project global menu'} | ${false} | ${true}        | ${false}        | ${true}
      ${'EE with epics'}       | ${true}  | ${false}       | ${true}         | ${true}
      ${'CE group no epics'}   | ${true}  | ${false}       | ${false}        | ${false}
    `(
      '$scenario shows selector: $expected',
      async ({ isGroup, fromGlobalMenu, hasEpicsFeature, expected }) => {
        createComponent({
          props: { isGroup, fromGlobalMenu },
          provide: { hasEpicsFeature },
        });

        await resolveAll();
        expect(findGroupProjectSelector().exists()).toBe(expected);
      },
    );

    it('updates available work item types when new namespace is selected', async () => {
      createComponent({
        props: { isGroup: true },
        provide: { hasEpicsFeature: true },
      });
      await resolveAll();

      findGroupProjectSelector().vm.$emit('selectNamespace', 'other-namespace/path');
      await nextTick();
      await resolveAll();

      expect(namespaceWorkItemTypesHandler).toHaveBeenCalledWith({
        fullPath: 'other-namespace/path',
      });
    });

    describe('preserves draft data across namespace changes', () => {
      const setupGroupForm = async () => {
        createComponent({
          props: { isGroup: true },
          provide: { hasEpicsFeature: true },
        });
        await resolveAll();
      };

      it('includes the typed title in the create mutation after namespace change', async () => {
        await setupGroupForm();

        await updateWorkItemTitle('Preserved title');
        findGroupProjectSelector().vm.$emit('selectNamespace', 'other-namespace/path');
        await nextTick();
        await resolveAll();

        await submitCreateForm();

        expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
          input: expect.objectContaining({ title: 'Preserved title' }),
          useWorkItemFeatures: false,
        });
      });

      it('includes the typed description in the create mutation after namespace change', async () => {
        await setupGroupForm();

        findDescriptionWidget().vm.$emit('updateDraft', 'Preserved description');
        await nextTick();
        await waitForPromises();

        findGroupProjectSelector().vm.$emit('selectNamespace', 'other-namespace/path');
        await nextTick();
        await resolveAll();

        await updateWorkItemTitle();
        await submitCreateForm();

        expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
          input: expect.objectContaining({
            descriptionWidget: { description: 'Preserved description' },
          }),
          useWorkItemFeatures: false,
        });
      });
    });

    describe('isNamespaceTypeGroup propagation to widgets', () => {
      it.each`
        scenario              | namespaceObject                                         | expectedIsGroup
        ${'Group typename'}   | ${{ fullPath: 'other-group', __typename: 'Group' }}     | ${true}
        ${'Project typename'} | ${{ fullPath: 'other-project', __typename: 'Project' }} | ${false}
      `(
        'sets is-group=$expectedIsGroup on child widgets when a namespace with $scenario is selected',
        async ({ namespaceObject, expectedIsGroup }) => {
          createComponent({
            props: { isGroup: true },
            provide: { hasEpicsFeature: true },
          });
          await resolveAll();

          findGroupProjectSelector().vm.$emit(
            'selectNamespace',
            namespaceObject.fullPath,
            namespaceObject,
          );
          await nextTick();
          await resolveAll();

          expect(findAssigneesWidget().props('isGroup')).toBe(expectedIsGroup);
        },
      );

      it('falls back to isGroup prop when no namespace object is emitted', async () => {
        createComponent({
          props: { isGroup: true },
          provide: { hasEpicsFeature: true },
        });
        await resolveAll();

        expect(findAssigneesWidget().props('isGroup')).toBe(true);
      });
    });
  });

  describe('Work item types dropdown', () => {
    it('renders with loading icon when namespaceWorkItemTypes query is loading', async () => {
      createComponent({ props: { preselectedWorkItemType: null, showProjectSelector: true } });
      await resolveAll();

      findProjectsSelector().vm.$emit('selectProject', 'fullPath');
      await nextTick();

      expect(findSelect().attributes('disabled')).not.toBeUndefined();
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('displays a list of work item types, excluding "Ticket" and including "Select type" options, when preselectedWorkItemType is not provided', async () => {
      createComponent({ props: { preselectedWorkItemType: null } });
      await resolveAll();
      const expectedOptions = workItemTypesWithConfiguration
        .filter((type) => type.canUserCreateItems)
        .concat({ name: 'Select type' }).length;

      expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
    });

    it('hides the type selector if preselectedWorkItemType is provided', async () => {
      createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_EPIC } });
      await resolveAll();

      expect(findSelect().exists()).toBe(false);
    });

    it('shows the type selector when alwaysShowWorkItemTypeSelect=true even if preselectedWorkItemType is provided', async () => {
      createComponent({
        props: {
          preselectedWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
          alwaysShowWorkItemTypeSelect: true,
        },
      });
      await resolveAll();

      expect(findSelect().exists()).toBe(true);
    });

    it('does not show the "Select type" option when preselectedWorkItemType is provided and alwaysShowWorkItemTypeSelect=true', async () => {
      createComponent({
        props: {
          preselectedWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
          alwaysShowWorkItemTypeSelect: true,
        },
      });
      await resolveAll();
      const expectedOptions = workItemTypesWithConfiguration.filter(
        (type) => type.canUserCreateItems,
      ).length;

      expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
    });

    it('selects a work item type on click', async () => {
      createComponent({ props: { preselectedWorkItemType: null } });
      await resolveAll();
      const mockId = 'Issue';

      findSelect().vm.$emit('input', mockId);
      await nextTick();

      expect(findSelect().attributes('value')).toBe(mockId);
    });

    it('sets new work item cache and emits changeType on select', async () => {
      createComponent({ props: { preselectedWorkItemType: null, relatedItem: mockRelatedItem } });
      await resolveAll();
      const mockId = 'Issue';

      findSelect().vm.$emit('change', mockId);
      await nextTick();

      expect(setNewWorkItemCache).toHaveBeenCalledWith(
        expect.objectContaining({
          fullPath: 'full-path',
          context: CREATION_CONTEXT_LIST_ROUTE,
          widgetDefinitions: expect.any(Array),
          workItemType: mockId,
          workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
          workItemTypeIconName: 'work-item-issue',
          relatedItemId: mockRelatedItem.id,
        }),
      );

      expect(wrapper.emitted('changeType')).toBeDefined();
    });

    it('sets selected work item type in localStorage draft', async () => {
      createComponent({ props: { preselectedWorkItemType: null, relatedItem: mockRelatedItem } });
      await resolveAll();
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
          iconName: 'work-item-issue',
        },
      });
    });

    it('hides title if set', async () => {
      createComponent({ props: { hideFormTitle: true } });
      await resolveAll();

      expect(findFormTitle().exists()).toBe(false);
    });

    it('filters work item type based on route parameter', async () => {
      createComponent();
      await resolveAll();

      expect(findSelect().exists()).toBe(false);
      expect(findFormTitle().text()).toBe('New Epic');
    });

    it('emits "changeType" with the type name when "selectedWorkItemTypeId" changes', async () => {
      // Initialize component without a preselected type so the dropdown is active
      createComponent({ props: { preselectedWorkItemType: null } });
      await resolveAll();

      const mockIssueType = namespaceWorkItemTypes.find(
        (type) => type.name === WORK_ITEM_TYPE_NAME_ISSUE,
      );

      // Trigger the watcher by updating the ID (simulating a select input)
      findSelect().vm.$emit('input', mockIssueType.id);
      await nextTick();

      expect(wrapper.emitted('changeType')).toContainEqual([WORK_ITEM_TYPE_NAME_ISSUE]);
    });
  });

  describe('Create work item', () => {
    it('emits work-item-created on successful mutation', async () => {
      setWindowLocation(
        '?discussion_to_resolve=f20989738bfe845f73a77a7109b1588852901befJD9I3FGU&merge_request_id=13',
      );
      const workItem = { ...createWorkItemMutationResponse.data.workItemCreate.workItem };
      // there is a mismatch between the response and the expected workItem object between CE and EE fixture
      // so we need to remove the `promotedToEpicUrl` property from the expected workItem object
      delete workItem.promotedToEpicUrl;

      createComponent();
      await resolveAll();

      findTitleInput().vm.$emit('updateDraft', 'Test title');
      await waitForPromises();
      await submitCreateForm();

      expect(wrapper.emitted('work-item-created')).toEqual([
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
      await resolveAll();

      findTitleInput().vm.$emit('updateDraft', 'Test title');
      await waitForPromises();
      await submitCreateForm();

      expect(clearDraft).toHaveBeenCalledTimes(2);
      expect(clearDraft).toHaveBeenNthCalledWith(1, typeSpecificAutosaveKey);
      expect(clearDraft).toHaveBeenNthCalledWith(2, sharedWidgetsAutosaveKey);
    });

    it('emits work-item-created for confidential work item', async () => {
      createComponent();
      await resolveAll();

      findConfidentialCheckbox().vm.$emit('change', true);
      await updateWorkItemTitle();
      wrapper.find('form').trigger('submit');
      await resolveAll();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          title: 'Test title',
          confidential: true,
        }),
        useWorkItemFeatures: false,
      });
    });

    it('creates work item with parent when parentId exists', async () => {
      const parentId = 'gid://gitlab/WorkItem/456';
      createComponent({ props: { parentId } });
      await resolveAll();

      await updateWorkItemTitle();
      wrapper.find('form').trigger('submit');

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          hierarchyWidget: { parentId },
        }),
        useWorkItemFeatures: false,
      });
    });

    it('creates work item within a specific namespace when project is selected', async () => {
      const fullPath = 'chosen/full/path';
      createComponent({ props: { showProjectSelector: true } });
      await resolveAll();

      findProjectsSelector().vm.$emit('selectProject', fullPath);
      await updateWorkItemTitle();
      wrapper.find('form').trigger('submit');

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          namespacePath: fullPath,
        }),
        useWorkItemFeatures: false,
      });
    });

    it('correct fullPath is provided to components when project is selected', async () => {
      const fullPath = 'chosen/full/path';
      createComponent({ props: { showProjectSelector: true } });
      await resolveAll();

      expect(findAssigneesWidget().props('fullPath')).toBe('full-path');

      findProjectsSelector().vm.$emit('selectProject', fullPath);

      await nextTick();

      expect(findAssigneesWidget().props('fullPath')).toBe(fullPath);
    });

    it('does not commit when title is empty', async () => {
      createComponent();
      await resolveAll();

      await updateWorkItemTitle('');
      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(findTitleInput().props('isValid')).toBe(false);
      expect(wrapper.emitted('work-item-created')).toBeUndefined();
    });

    it('updates work item title on update mutation', async () => {
      createComponent();
      await resolveAll();

      await updateWorkItemTitle();

      expect(findTitleInput().props('title')).toBe('Test title');
    });

    it('when title input field has a text renders Create button when work item type is selected', async () => {
      createComponent();
      await resolveAll();

      await updateWorkItemTitle();

      expect(findCreateButton().props('disabled')).toBe(false);
    });

    it('when title input text is deleted after typed, title is not valid anymore to submit', async () => {
      createComponent();
      await resolveAll();

      await updateWorkItemTitle();

      expect(findTitleInput().props('title')).toBe('Test title');

      await updateWorkItemTitle('');
      wrapper.find('form').trigger('submit');
      await waitForPromises();

      expect(findTitleInput().props('title')).toBe('');
      expect(findTitleInput().props('isValid')).toBe(false);
      expect(wrapper.emitted('work-item-created')).toBeUndefined();
    });

    it('shows an alert on mutation top-level error', async () => {
      createComponent({ mutationHandler: () => Promise.reject() });
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(findAlert().text()).toBe('Something went wrong when creating Epic. Please try again.');
    });

    it('shows an alert on mutation error', async () => {
      createComponent({ mutationHandler: mutationErrorHandler });
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(findAlert().text()).toBe('an error');
    });

    it('includes createSource when prop is provided', async () => {
      createComponent({
        props: {
          createSource: WORK_ITEM_CREATE_SOURCES.WORK_ITEM_LIST,
        },
      });
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          createSource: WORK_ITEM_CREATE_SOURCES.WORK_ITEM_LIST,
        }),
        useWorkItemFeatures: false,
      });
    });

    it('uses VULNERABILITY source when vulnerability_id param exists', async () => {
      setWindowLocation('?vulnerability_id=123');
      createComponent();
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          createSource: WORK_ITEM_CREATE_SOURCES.VULNERABILITY,
        }),
        useWorkItemFeatures: false,
      });
    });

    it('does not include createSource when neither prop nor vulnerability_id exists', async () => {
      createComponent();
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.not.objectContaining({
          createSource: expect.anything(),
        }),
        useWorkItemFeatures: false,
      });
    });

    it('prioritizes createSource prop over vulnerability_id', async () => {
      setWindowLocation('?vulnerability_id=123');
      createComponent({
        props: {
          createSource: WORK_ITEM_CREATE_SOURCES.GLOBAL_NAV,
        },
      });
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          createSource: WORK_ITEM_CREATE_SOURCES.GLOBAL_NAV, // Uses prop, not VULNERABILITY
        }),
        useWorkItemFeatures: false,
      });
    });
  });

  describe('Create work item widgets for epic work item type', () => {
    describe('default', () => {
      beforeEach(async () => {
        createComponent();
        await resolveAll();
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

    describe('with canRollUp config', () => {
      it.each([true, false])(
        'renders the dates widget with shouldRollUp %s when canRollUp is %s',
        async (canRollUp) => {
          createComponent({
            provide: {
              getWorkItemTypeConfiguration: jest.fn().mockReturnValue({
                widgetDefinitions: [
                  {
                    type: WIDGET_TYPE_START_AND_DUE_DATE,
                    canRollUp,
                  },
                ],
              }),
            },
          });
          await resolveAll();

          expect(findDatesWidget().props('shouldRollUp')).toBe(canRollUp);
        },
      );
    });

    it('uses the description prop as the initial description value when defined', async () => {
      const description = 'i am a description';
      createComponent({ props: { description } });
      await resolveAll();

      expect(findDescriptionWidget().props('description')).toBe(description);
    });

    it('uses the title prop as the initial title value when defined', async () => {
      const title = 'i am a title';
      createComponent({ props: { title } });
      await resolveAll();

      expect(findTitleInput().props('title')).toBe(title);
    });
  });

  describe('Create work item widgets for Issue work item type', () => {
    describe('default', () => {
      beforeEach(async () => {
        createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE } });
        await resolveAll();
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

    describe('when workItemFeaturesField feature flag is enabled', () => {
      beforeEach(async () => {
        gon.features = { workItemFeaturesField: true };
        jest.fn().mockResolvedValue(createWorkItemQueryResponseWithFeatures());
        createComponent({
          props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE },
          mutationHandler: createWorkItemSuccessHandler,
        });

        await resolveAll();
      });

      it('renders the work item milestone widget from features', () => {
        expect(findMilestoneWidget().exists()).toBe(true);
      });

      it('renders the work item assignees widget from features', () => {
        expect(findAssigneesWidget().exists()).toBe(true);
      });

      it('renders the work item CRM contacts widget from features', () => {
        expect(findCrmContactsWidget().exists()).toBe(true);
      });
    });
  });

  describe('Create work item widgets for Incident work item type', () => {
    describe('with isIncidentManagement=true', () => {
      beforeEach(async () => {
        createComponent({
          props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_INCIDENT },
          provide: {
            getWorkItemTypeConfiguration: jest.fn().mockReturnValue({ isIncidentManagement: true }),
          },
        });
        await resolveAll();
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
      await resolveAll();

      expect(findConfidentialCheckbox().attributes('checked')).toBe('true');
    });

    it('is not checked when parameter issue[confidential]!=true', async () => {
      setWindowLocation('?issue[confidential]=tru');
      createComponent();
      await resolveAll();

      expect(findConfidentialCheckbox().attributes('checked')).toBeUndefined();
    });

    it('is checked when parameter vulnerability_id exists', async () => {
      setWindowLocation('?vulnerability_id=123');
      createComponent();
      await resolveAll();

      expect(findConfidentialCheckbox().attributes('checked')).toBe('true');
    });

    it('is not checked when parameter vulnerability_id does not exist', async () => {
      setWindowLocation('?vulnerability_id_is_not_here=123');
      createComponent();
      await resolveAll();

      expect(findConfidentialCheckbox().attributes('checked')).toBeUndefined();
    });

    it('renders confidentiality checkbox for a group', async () => {
      createComponent({
        props: {
          isGroup: true,
        },
      });

      await resolveAll();

      const confidentialCheckbox = findConfidentialCheckbox();

      expect(confidentialCheckbox.text()).toBe(
        'Turn on confidentiality: Limit visibility to group members with at least the Planner role.',
      );
    });

    it('renders confidentiality checkbox for a project', async () => {
      createComponent();

      await resolveAll();

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
      await resolveAll();
    });

    it('renders the correct text for the checkbox', () => {
      expect(findRelatesToCheckbox().text()).toMatchInterpolatedText(
        'Mark this item as related to: Epic #1',
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
        useWorkItemFeatures: false,
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
        useWorkItemFeatures: false,
      });
    });
  });

  describe('form buttons', () => {
    it('shows buttons on right and sticky when isModal', async () => {
      createComponent({ props: { isModal: true } });
      await resolveAll();

      expect(findFormButtons().classes('gl-sticky')).toBe(true);
      expect(findFormButtons().classes('gl-justify-between')).toBe(true);
      expect(findFormButtons().findAllComponents(GlButton).at(0).text()).toBe('Cancel');
      expect(findFormButtons().findAllComponents(GlButton).at(1).text()).toBe('Create Epic');
    });

    it('shows buttons on left and sticky when not isModal', async () => {
      createComponent({ props: { isModal: false } });
      await resolveAll();

      expect(findFormButtons().classes('gl-sticky')).toBe(true);
      expect(findFormButtons().classes('gl-justify-between')).toBe(true);
      expect(findFormButtons().findAllComponents(GlButton).at(0).text()).toBe('Create Epic');
      expect(findFormButtons().findAllComponents(GlButton).at(1).text()).toBe('Cancel');
    });

    it('shows contribution guidelines link when contributing.md exists', async () => {
      createComponent({ provide: { contributionGuidePath: 'contribution/guide/path' } });
      await resolveAll();

      expect(findFormButtons().findComponent(GlLink).text()).toBe('contribution guidelines');
      expect(findFormButtons().findComponent(GlLink).attributes('href')).toBe(
        'contribution/guide/path',
      );
    });

    it('does not show contribution guidelines link when contributing.md does not exist', async () => {
      createComponent({ provide: { contributionGuidePath: undefined } });
      await resolveAll();

      expect(findFormButtons().findComponent(GlLink).exists()).toBe(false);
    });
  });

  describe('Keyboard submit events', () => {
    beforeEach(async () => {
      createComponent();
      await resolveAll();
      await updateWorkItemTitle();
    });

    it.each`
      key       | keyOptions
      ${'CTRL'} | ${{ key: 'Enter', ctrlKey: true }}
      ${'CMD'}  | ${{ key: 'Enter', metaKey: true }}
    `(
      'creates work item and stops $key+Enter from propagating to other handlers',
      ({ keyOptions }) => {
        const event = new KeyboardEvent('keydown', { cancelable: true, ...keyOptions });
        jest.spyOn(event, 'preventDefault');
        jest.spyOn(event, 'stopImmediatePropagation');
        document.dispatchEvent(event);

        expect(createWorkItemSuccessHandler).toHaveBeenCalled();
        expect(event.preventDefault).toHaveBeenCalled();
        expect(event.stopImmediatePropagation).toHaveBeenCalled();
      },
    );
  });

  describe('when saving work item during create', () => {
    it('skips updateDraftData when loading is true', async () => {
      createComponent();
      await resolveAll();
      await updateWorkItemTitle();

      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      wrapper.find('form').trigger('submit');

      apolloProvider.defaultClient.mutate.mockClear();
      findTitleInput().vm.$emit('updateDraft', 'new title');
      await nextTick();

      expect(apolloProvider.defaultClient.mutate).not.toHaveBeenCalledWith(
        expect.objectContaining({ mutation: updateNewWorkItemMutation }),
      );
    });

    it('skips handleUpdateWidgetDraft when loading is true', async () => {
      createComponent();
      await resolveAll();
      await updateWorkItemTitle();

      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      wrapper.find('form').trigger('submit');

      apolloProvider.defaultClient.mutate.mockClear();
      findAssigneesWidget().vm.$emit('updateWidgetDraft', { assignees: [] });
      await nextTick();

      expect(apolloProvider.defaultClient.mutate).not.toHaveBeenCalledWith(
        expect.objectContaining({ mutation: updateNewWorkItemMutation }),
      );
    });

    it('clears autosave draft before emitting work-item-created', async () => {
      createComponent({
        props: {
          relatedItem: mockRelatedItem,
        },
      });
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      const clearedAt = clearDraft.mock.invocationCallOrder[0];
      const emittedAt = wrapper.emitted('work-item-created').length;

      expect(clearDraft).toHaveBeenCalled();
      expect(emittedAt).toBe(1);
      expect(clearedAt).toBeDefined();
    });
  });

  it('renders work item title suggestions below work item title', async () => {
    createComponent();
    await resolveAll();

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
        namespace: {
          ...namespaceWorkItemTypesQueryResponse.data.namespace,
          userPermissions: {
            setNewWorkItemMetadata: false,
          },
        },
      },
    };

    createComponent({ namespaceQueryResponse });
    await resolveAll();

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
      await resolveAll();

      expect(setNewWorkItemCache).toHaveBeenCalledWith(
        expect.objectContaining({
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
        }),
      );
    });

    it.each([
      CREATION_CONTEXT_SUPER_SIDEBAR,
      CREATION_CONTEXT_RELATED_ITEM,
      CREATION_CONTEXT_DESCRIPTION_CHECKLIST,
    ])('does not read DOM params when creationContext is %s', async (creationContext) => {
      setHTMLFixture(`
        <div class="new-issue-params hidden">
          <div class="params-title">i am a title</div>
          <div class="params-description">i am a description</div>
        </div>`);
      createComponent({ props: { creationContext } });
      await resolveAll();

      expect(setNewWorkItemCache).toHaveBeenCalledWith(
        expect.objectContaining({
          workItemTitle: '',
          workItemDescription: '',
        }),
      );
    });
  });

  describe('New work item to resolve threads', () => {
    it('when not resolving any thread, does not pass resolve params to mutation', async () => {
      createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE } });
      await resolveAll();

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
      await resolveAll();

      await updateWorkItemTitle();
      await submitCreateForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
        input: expect.objectContaining({
          discussionsToResolve: {
            discussionId: '13',
            noteableId: 'gid://gitlab/MergeRequest/13',
          },
        }),
        useWorkItemFeatures: false,
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
        await resolveAll();
      });

      it('renders text', () => {
        expect(findResolveDiscussionSection().text()).toMatchInterpolatedText(
          'Creating this Issue will resolve the thread in !1 (discussion 1224)',
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
          useWorkItemFeatures: false,
        });
      });
    });
  });

  describe('last used work item type persistence', () => {
    describe('when the form is submitted', () => {
      it('stores the last used work item type against the selected namespace on submit', async () => {
        createComponent({ props: { preselectedWorkItemType: WORK_ITEM_TYPE_NAME_ISSUE } });
        await resolveAll();
        await updateWorkItemTitle();
        await submitCreateForm();

        expect(localStorage.setItem).toHaveBeenCalledWith(
          'freq-wi-type:full-path',
          'gid://gitlab/WorkItems::Type/1',
        );
      });
    });
    describe('loading the last used work item type', () => {
      beforeEach(async () => {
        createComponent({
          props: { isGroup: true },
          provide: { hasEpicsFeature: true },
        });
        await resolveAll();
      });
      it('when the form loads', () => {
        expect(localStorage.getItem).toHaveBeenCalledWith('freq-wi-type:full-path');
      });
      it('when selecting a different namespace', async () => {
        findGroupProjectSelector().vm.$emit('selectNamespace', 'other-namespace/path');
        await nextTick();
        await resolveAll();
        expect(localStorage.getItem).toHaveBeenCalledWith('freq-wi-type:other-namespace/path');
      });
    });
  });
});
