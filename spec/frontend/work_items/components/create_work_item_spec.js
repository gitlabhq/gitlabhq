import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlFormSelect, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import namespaceWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/namespace_work_item_types.query.graphql.json';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemCrmContacts from '~/work_items/components/work_item_crm_contacts.vue';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemParent from '~/work_items/components/work_item_parent.vue';
import WorkItemProjectsListbox from '~/work_items/components/work_item_links/work_item_projects_listbox.vue';
import TitleSuggestions from '~/issues/new/components/title_suggestions.vue';
import {
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_VALUE_INCIDENT,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  WORK_ITEM_TYPE_VALUE_MAP,
  WORK_ITEM_TYPE_VALUE_TASK,
  WORK_ITEMS_TYPE_MAP,
} from '~/work_items/constants';
import { setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  createWorkItemMutationErrorResponse,
  createWorkItemMutationResponse,
  createWorkItemQueryResponse,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('~/work_items/graphql/cache_utils', () => ({
  setNewWorkItemCache: jest.fn(),
}));

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockReturnValue('13'),
  mergeUrlParams: jest.fn().mockReturnValue('/branches?state=all&search=%5Emain%24'),
  joinPaths: jest.fn(),
  setUrlParams: jest
    .fn()
    .mockReturnValue('/project/Project/-/settings/repository/branch_rules?branch=main'),
  setUrlFragment: jest.fn(),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

Vue.use(VueApollo);

describe('Create work item component', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;
  let mockApollo;

  useLocalStorageSpy();

  const createWorkItemSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const mutationErrorHandler = jest.fn().mockResolvedValue(createWorkItemMutationErrorResponse);
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
  const findCrmContactsWidget = () => wrapper.findComponent(WorkItemCrmContacts);
  const findMilestoneWidget = () => wrapper.findComponent(WorkItemMilestone);
  const findParentWidget = () => wrapper.findComponent(WorkItemParent);
  const findProjectsSelector = () => wrapper.findComponent(WorkItemProjectsListbox);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findTitleSuggestions = () => wrapper.findComponent(TitleSuggestions);
  const findConfidentialCheckbox = () => wrapper.find('[data-testid="confidential-checkbox"]');
  const findRelatesToCheckbox = () => wrapper.find('[data-testid="relates-to-checkbox"]');
  const findCreateWorkItemView = () => wrapper.find('[data-testid="create-work-item-view"]');
  const findFormButtons = () => wrapper.find('[data-testid="form-buttons"]');
  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');

  const createComponent = ({
    props = {},
    mutationHandler = createWorkItemSuccessHandler,
    workItemTypeName = WORK_ITEM_TYPE_ENUM_EPIC,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [workItemByIidQuery, workItemQuerySuccessHandler],
        [createWorkItemMutation, mutationHandler],
        [namespaceWorkItemTypesQuery, namespaceWorkItemTypesHandler],
      ],
      resolvers,
    );

    wrapper = shallowMount(CreateWorkItem, {
      apolloProvider: mockApollo,
      propsData: {
        workItemTypeName,
        ...props,
      },
      provide: {
        fullPath: 'full-path',
        groupPath: 'group-path',
        hasIssuableHealthStatusFeature: false,
        hasIterationsFeature: true,
        hasIssueWeightsFeature: false,
      },
      stubs: {
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
  });

  describe('Default', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not render error by default', () => {
      expect(findTitleInput().props('isValid')).toBe(true);
      expect(findAlert().exists()).toBe(false);
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
  });

  describe('Cache clearing', () => {
    it('Default', async () => {
      createComponent();
      await waitForPromises();
      const AUTO_SAVE_KEY = 'autosave/new-full-path-epic-draft';

      findCancelButton().vm.$emit('click');
      await nextTick();

      expect(localStorage.removeItem).toHaveBeenCalledWith(AUTO_SAVE_KEY);
      expect(setNewWorkItemCache).toHaveBeenCalled();
    });

    it.each(Object.keys(WORK_ITEMS_TYPE_MAP))(
      'Clears cache on cancel for workItemType: %s with the correct data',
      async (type) => {
        const typeName = WORK_ITEMS_TYPE_MAP[type].value;
        const expectedWorkItemTypeData =
          namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.find(
            ({ name }) => name === typeName,
          );
        createComponent({ workItemTypeName: WORK_ITEM_TYPE_VALUE_MAP[typeName] });
        await waitForPromises();

        findCancelButton().vm.$emit('click');
        await nextTick();

        expect(setNewWorkItemCache).toHaveBeenCalledWith(
          'full-path',
          expectedWorkItemTypeData.widgetDefinitions,
          expectedWorkItemTypeData.name,
          expectedWorkItemTypeData.id,
          expectedWorkItemTypeData.iconName,
        );
      },
    );
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
      createComponent({ props: { showProjectSelector: true } });
      await waitForPromises();

      expect(findProjectsSelector().props('selectedProjectFullPath')).toBe('full-path');
    });
  });

  describe('Work item types dropdown', () => {
    it('displays a list of work item types including "Select type" option when workItemTypeName is not provided', async () => {
      createComponent({ props: { workItemTypeName: null } });
      await waitForPromises();
      // +1 for the "Select type" option
      const expectedOptions =
        namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.length + 1;

      expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
    });

    it('hides the type selector if workItemTypeName is provided', async () => {
      createComponent({ props: { workItemTypeName: WORK_ITEM_TYPE_ENUM_EPIC } });
      await waitForPromises();

      expect(findSelect().exists()).toBe(false);
    });

    it('shows the type selector when alwaysShowWorkItemTypeSelect=true even if workItemTypeName is provided', async () => {
      createComponent({
        props: { workItemTypeName: WORK_ITEM_TYPE_ENUM_EPIC, alwaysShowWorkItemTypeSelect: true },
      });
      await waitForPromises();

      expect(findSelect().exists()).toBe(true);
    });

    it('does not show the "Select type" option when workItemTypeName is provided and alwaysShowWorkItemTypeSelect=true', async () => {
      createComponent({
        props: { workItemTypeName: WORK_ITEM_TYPE_ENUM_EPIC, alwaysShowWorkItemTypeSelect: true },
      });
      await waitForPromises();

      expect(findSelect().attributes('options').split(',')).toHaveLength(
        namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.length,
      );
    });

    it('restricts the type selector to types provided by allowedWorkItemTypes', async () => {
      const allowedWorkItemTypes = [
        WORK_ITEM_TYPE_VALUE_INCIDENT,
        WORK_ITEM_TYPE_VALUE_ISSUE,
        WORK_ITEM_TYPE_VALUE_TASK,
      ];
      createComponent({ props: { workItemTypeName: null, allowedWorkItemTypes } });
      await waitForPromises();
      // +1 for the "Select type" option
      const expectedOptions = allowedWorkItemTypes.length + 1;

      expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
    });

    it('selects a work item type on click', async () => {
      createComponent({ props: { workItemTypeName: null } });
      await waitForPromises();
      const mockId = 'Issue';

      findSelect().vm.$emit('input', mockId);
      await nextTick();

      expect(findSelect().attributes('value')).toBe(mockId);
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
      createComponent();
      await waitForPromises();

      findTitleInput().vm.$emit('updateDraft', 'Test title');
      await waitForPromises();
      await submitCreateForm();

      expect(wrapper.emitted('workItemCreated')).toEqual([
        [
          {
            workItem: createWorkItemMutationResponse.data.workItemCreate.workItem,
            numberOfDiscussionsResolved: '1',
          },
        ],
      ]);
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
        createComponent({ workItemTypeName: WORK_ITEM_TYPE_ENUM_ISSUE });
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

      it('renders the work item parent widget', () => {
        expect(findParentWidget().exists()).toBe(true);
      });
    });
  });

  describe('With related item', () => {
    const id = 'gid://gitlab/WorkItem/1';
    const type = 'Epic';
    const reference = 'full-path#1';
    const webUrl = 'web/url';

    beforeEach(async () => {
      createComponent({ props: { relatedItem: { id, type, reference, webUrl } } });
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
    it('shows buttons on right and sticky when stickyFormSubmit', async () => {
      createComponent({ props: { stickyFormSubmit: true } });
      await waitForPromises();

      expect(findFormButtons().classes('gl-sticky')).toBe(true);
      expect(findFormButtons().classes('gl-justify-end')).toBe(true);
      expect(findFormButtons().findAllComponents(GlButton).at(0).text()).toBe('Cancel');
      expect(findFormButtons().findAllComponents(GlButton).at(1).text()).toBe('Create epic');
    });

    it('shows buttons on left and inside the grid when not stickyFormSubmit', async () => {
      createComponent({ props: { stickyFormSubmit: false } });
      await waitForPromises();

      expect(findFormButtons().classes('gl-sticky')).toBe(false);
      expect(findFormButtons().classes('gl-justify-end')).toBe(false);
      expect(findFormButtons().findAllComponents(GlButton).at(0).text()).toBe('Create epic');
      expect(findFormButtons().findAllComponents(GlButton).at(1).text()).toBe('Cancel');
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

  describe('New work item to resolve threads', () => {
    it('when not resolving any thread, does not pass resolve params to mutation', async () => {
      createComponent({ singleWorkItemType: true, workItemTypeName: WORK_ITEM_TYPE_ENUM_ISSUE });
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
      setWindowLocation('?merge_request_id=13');

      createComponent({ singleWorkItemType: true, workItemTypeName: WORK_ITEM_TYPE_ENUM_ISSUE });
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

    it('when resolving one thread in a merge request', async () => {
      setWindowLocation(
        '?discussion_to_resolve=13&merge_request_to_resolve_discussions_of=112&merge_request_id=13',
      );

      createComponent({ singleWorkItemType: true, workItemTypeName: WORK_ITEM_TYPE_ENUM_ISSUE });
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
  });
});
