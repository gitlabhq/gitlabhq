import { GlAlert, GlEmptyState } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import WorkItemLoading from '~/work_items/components/work_item_loading.vue';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemAncestors from '~/work_items/components/work_item_ancestors/work_item_ancestors.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import WorkItemTitleWithEdit from '~/work_items/components/work_item_title_with_edit.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import WorkItemTodos from '~/work_items/components/work_item_todos.vue';
import { i18n } from '~/work_items/constants';
import groupWorkItemByIidQuery from '~/work_items/graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';

import {
  groupWorkItemByIidResponseFactory,
  mockParent,
  workItemByIidResponseFactory,
  objectiveType,
  epicType,
  mockWorkItemCommentNote,
  mockBlockingLinkedItem,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemByIidResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryResponseWithNoPermissions = workItemByIidResponseFactory({
    canUpdate: false,
    canDelete: false,
  });
  const groupWorkItemQueryResponse = groupWorkItemByIidResponseFactory({
    canUpdate: true,
    canDelete: true,
  });
  const workItemQueryResponseWithoutParent = workItemByIidResponseFactory({
    parent: null,
    canUpdate: true,
    canDelete: true,
  });
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const successHandlerWithNoPermissions = jest
    .fn()
    .mockResolvedValue(workItemQueryResponseWithNoPermissions);
  const groupSuccessHandler = jest.fn().mockResolvedValue(groupWorkItemQueryResponse);
  const showModalHandler = jest.fn();
  const { id } = workItemQueryResponse.data.workspace.workItems.nodes[0];
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findWorkItemLoading = () => wrapper.findComponent(WorkItemLoading);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);
  const findCreatedUpdated = () => wrapper.findComponent(WorkItemCreatedUpdated);
  const findWorkItemDescription = () => wrapper.findComponent(WorkItemDescription);
  const findWorkItemAttributesWrapper = () => wrapper.findComponent(WorkItemAttributesWrapper);
  const findAncestors = () => wrapper.findComponent(WorkItemAncestors);
  const findCloseButton = () => wrapper.findByTestId('work-item-close');
  const findWorkItemType = () => wrapper.findByTestId('work-item-type');
  const findHierarchyTree = () => wrapper.findComponent(WorkItemTree);
  const findWorkItemRelationships = () => wrapper.findComponent(WorkItemRelationships);
  const findNotesWidget = () => wrapper.findComponent(WorkItemNotes);
  const findModal = () => wrapper.findComponent(WorkItemDetailModal);
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findWorkItemTodos = () => wrapper.findComponent(WorkItemTodos);
  const findStickyHeader = () => wrapper.findComponent(WorkItemStickyHeader);
  const findWorkItemTwoColumnViewContainer = () => wrapper.findByTestId('work-item-overview');
  const findRightSidebar = () => wrapper.findByTestId('work-item-overview-right-sidebar');
  const findEditButton = () => wrapper.findByTestId('work-item-edit-form-button');
  const findWorkItemTitleWithEdit = () => wrapper.findComponent(WorkItemTitleWithEdit);

  const createComponent = ({
    isGroup = false,
    isModal = false,
    updateInProgress = false,
    workItemIid = '1',
    handler = successHandler,
    mutationHandler,
    error = undefined,
    workItemsMvc2Enabled = false,
    workItemsBeta = false,
    linkedWorkItemsEnabled = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemDetail, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, handler],
        [groupWorkItemByIidQuery, groupSuccessHandler],
        [updateWorkItemMutation, mutationHandler],
        [workItemUpdatedSubscription, workItemUpdatedSubscriptionHandler],
      ]),
      isLoggedIn: isLoggedIn(),
      propsData: {
        isModal,
        workItemIid,
      },
      data() {
        return {
          updateInProgress,
          error,
        };
      },
      provide: {
        glFeatures: {
          workItemsMvc2: workItemsMvc2Enabled,
          linkedWorkItems: linkedWorkItemsEnabled,
          workItemsBeta,
        },
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        fullPath: 'group/project',
        isGroup,
        reportAbusePath: '/report/abuse/path',
      },
      stubs: {
        WorkItemAncestors: true,
        WorkItemWeight: true,
        WorkItemIteration: true,
        WorkItemHealthStatus: true,
        WorkItemDetailModal: stubComponent(WorkItemDetailModal, {
          methods: {
            show: showModalHandler,
          },
        }),
      },
    });
  };

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
  });

  afterEach(() => {
    setWindowLocation('');
  });

  describe('when there is no `workItemIid` prop', () => {
    beforeEach(async () => {
      createComponent({ workItemIid: null });
      await waitForPromises();
    });

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });

    it('skips the work item updated subscription', () => {
      expect(workItemUpdatedSubscriptionHandler).not.toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders skeleton loader', () => {
      expect(findWorkItemLoading().exists()).toBe(true);
      expect(findWorkItemTitle().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render skeleton', () => {
      expect(findWorkItemLoading().exists()).toBe(false);
      expect(findWorkItemTitle().exists()).toBe(true);
    });

    it('updates the document title', () => {
      expect(document.title).toEqual('Updated title · Task · test-project-path');
    });

    it('renders todos widget if logged in', () => {
      expect(findWorkItemTodos().exists()).toBe(true);
    });

    it('calls the work item updated subscription', () => {
      expect(workItemUpdatedSubscriptionHandler).toHaveBeenCalledWith({ id });
    });
  });

  describe('close button', () => {
    describe('when isModal prop is false', () => {
      it('does not render', async () => {
        createComponent({ isModal: false });
        await waitForPromises();

        expect(findCloseButton().exists()).toBe(false);
      });
    });

    describe('when isModal prop is true', () => {
      it('renders', async () => {
        createComponent({ isModal: true });
        await waitForPromises();

        expect(findCloseButton().props('icon')).toBe('close');
        expect(findCloseButton().attributes('aria-label')).toBe('Close');
      });

      it('emits `close` event when clicked', async () => {
        createComponent({ isModal: true });
        await waitForPromises();

        findCloseButton().vm.$emit('click');

        expect(wrapper.emitted('close')).toEqual([[]]);
      });
    });
  });

  describe('confidentiality', () => {
    const errorMessage = 'Mutation failed';
    const confidentialWorkItem = workItemByIidResponseFactory({ confidential: true });
    const mutationHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: confidentialWorkItem.data.workspace.workItems.nodes[0],
          errors: [],
        },
      },
    });

    it('sends updateInProgress props to child component', async () => {
      createComponent({ mutationHandler });
      await waitForPromises();

      findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
      await nextTick();

      expect(findCreatedUpdated().props('updateInProgress')).toBe(true);
    });

    it('emits workItemUpdated when mutation is successful', async () => {
      createComponent({ mutationHandler });
      await waitForPromises();

      findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
      await waitForPromises();

      expect(wrapper.emitted('workItemUpdated')).toEqual([[{ confidential: true }]]);
      expect(mutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          confidential: true,
        },
      });
    });

    it('shows an alert when mutation fails', async () => {
      createComponent({ mutationHandler: jest.fn().mockRejectedValue(new Error(errorMessage)) });
      await waitForPromises();

      findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
      await waitForPromises();

      expect(wrapper.emitted('workItemUpdated')).toBeUndefined();
      expect(findAlert().text()).toBe(errorMessage);
    });
  });

  describe('description', () => {
    it('does not show description widget if loading description fails', () => {
      createComponent();

      expect(findWorkItemDescription().exists()).toBe(false);
    });

    it('shows description widget if description loads', async () => {
      createComponent();
      await waitForPromises();

      expect(findWorkItemDescription().exists()).toBe(true);
    });
  });

  describe('ancestors widget', () => {
    it('does not show ancestors widget by default', () => {
      createComponent();

      expect(findAncestors().exists()).toBe(false);
    });

    it('does not show ancestors widget if there is not a parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();

      expect(findAncestors().exists()).toBe(false);
    });

    it('shows title in the header when there is no parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();
      expect(findWorkItemType().classes()).toEqual(['gl-sm-display-block!', 'gl-w-full']);
    });

    describe('with parent', () => {
      beforeEach(() => {
        const parentResponse = workItemByIidResponseFactory(mockParent);
        createComponent({ handler: jest.fn().mockResolvedValue(parentResponse) });

        return waitForPromises();
      });

      it('shows ancestors widget if there is a parent', () => {
        expect(findAncestors().exists()).toBe(true);
      });

      it('does not show title in the header when parent exists', () => {
        expect(findWorkItemType().classes()).toEqual(['gl-sm-display-none!', 'gl-mt-3']);
      });
    });
  });

  it('shows empty state with an error message when the work item query was unsuccessful', async () => {
    const errorHandler = jest.fn().mockRejectedValue('Oops');
    createComponent({ handler: errorHandler });
    await waitForPromises();

    expect(errorHandler).toHaveBeenCalled();
    expect(findEmptyState().props('description')).toBe(i18n.fetchError);
    expect(findWorkItemTitle().exists()).toBe(false);
  });

  it('shows an error message when WorkItemTitle emits an `error` event', async () => {
    createComponent();
    await waitForPromises();
    const updateError = 'Failed to update';

    findWorkItemTitle().vm.$emit('error', updateError);
    await waitForPromises();

    expect(findAlert().text()).toBe(updateError);
  });

  describe('when project context', () => {
    it('calls the project work item query', async () => {
      createComponent();
      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
    });

    it('skips calling the group work item query', async () => {
      createComponent();
      await waitForPromises();

      expect(groupSuccessHandler).not.toHaveBeenCalled();
    });

    it('skips calling the project work item query when there is no workItemIid', async () => {
      createComponent({ workItemIid: null });
      await waitForPromises();

      expect(successHandler).not.toHaveBeenCalled();
    });

    it('calls the project work item query when isModal=true', async () => {
      createComponent({ isModal: true });
      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
    });
  });

  describe('when group context', () => {
    it('skips calling the project work item query', async () => {
      createComponent({ isGroup: true });
      await waitForPromises();

      expect(successHandler).not.toHaveBeenCalled();
    });

    it('calls the group work item query', async () => {
      createComponent({ isGroup: true });
      await waitForPromises();

      expect(groupSuccessHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
    });

    it('skips calling the group work item query when there is no workItemIid', async () => {
      createComponent({ isGroup: true, workItemIid: null });
      await waitForPromises();

      expect(groupSuccessHandler).not.toHaveBeenCalled();
    });

    it('calls the group work item query when isModal=true', async () => {
      createComponent({ isGroup: true, isModal: true });
      await waitForPromises();

      expect(groupSuccessHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
    });
  });

  describe('hierarchy widget', () => {
    it('does not render children tree by default', async () => {
      createComponent();
      await waitForPromises();

      expect(findHierarchyTree().exists()).toBe(false);
    });

    describe('work item has children', () => {
      const objectiveWorkItem = workItemByIidResponseFactory({
        workItemType: objectiveType,
        confidential: true,
      });
      const objectiveHandler = jest.fn().mockResolvedValue(objectiveWorkItem);

      const epicWorkItem = workItemByIidResponseFactory({
        workItemType: epicType,
      });
      const epicHandler = jest.fn().mockResolvedValue(epicWorkItem);

      it.each`
        type           | handler
        ${'Objective'} | ${objectiveHandler}
        ${'Epic'}      | ${epicHandler}
      `('renders children tree when work item type is $type', async ({ handler }) => {
        createComponent({ handler });
        await waitForPromises();

        expect(findHierarchyTree().exists()).toBe(true);
      });

      it('renders a modal', async () => {
        createComponent({ handler: objectiveHandler });
        await waitForPromises();

        expect(findModal().exists()).toBe(true);
      });

      it('opens the modal with the child when `show-modal` is emitted', async () => {
        createComponent({ handler: objectiveHandler, workItemsMvc2Enabled: true });
        await waitForPromises();

        const event = {
          preventDefault: jest.fn(),
        };

        findHierarchyTree().vm.$emit('show-modal', {
          event,
          modalWorkItem: { id: 'childWorkItemId' },
        });
        await waitForPromises();

        expect(wrapper.findComponent(WorkItemDetailModal).props().workItemId).toBe(
          'childWorkItemId',
        );
        expect(showModalHandler).toHaveBeenCalled();
      });

      describe('work item is rendered in a modal and has children', () => {
        beforeEach(async () => {
          createComponent({
            isModal: true,
            handler: objectiveHandler,
            workItemsMvc2Enabled: true,
          });

          await waitForPromises();
        });

        it('does not render a new modal', () => {
          expect(findModal().exists()).toBe(false);
        });

        it('emits `update-modal` when `show-modal` is emitted', async () => {
          const event = {
            preventDefault: jest.fn(),
          };

          findHierarchyTree().vm.$emit('show-modal', {
            event,
            modalWorkItem: { id: 'childWorkItemId' },
          });
          await waitForPromises();

          expect(wrapper.emitted('update-modal')).toBeDefined();
        });
      });
    });
  });

  describe('relationship widget', () => {
    it('does not render linked items by default', async () => {
      createComponent();
      await waitForPromises();

      expect(findWorkItemRelationships().exists()).toBe(false);
    });

    describe('work item has children', () => {
      const mockWorkItemLinkedItem = workItemByIidResponseFactory({
        linkedItems: mockBlockingLinkedItem,
      });
      const handler = jest.fn().mockResolvedValue(mockWorkItemLinkedItem);

      it('renders relationship widget when work item has linked items', async () => {
        createComponent({ handler, linkedWorkItemsEnabled: true });
        await waitForPromises();

        expect(findWorkItemRelationships().exists()).toBe(true);
      });

      it('opens the modal with the linked item when `showModal` is emitted', async () => {
        createComponent({
          handler,
          linkedWorkItemsEnabled: true,
          workItemsMvc2Enabled: true,
        });
        await waitForPromises();

        const event = {
          preventDefault: jest.fn(),
        };

        findWorkItemRelationships().vm.$emit('showModal', {
          event,
          modalWorkItem: { id: 'childWorkItemId' },
        });
        await waitForPromises();

        expect(findModal().props().workItemId).toBe('childWorkItemId');
        expect(showModalHandler).toHaveBeenCalled();
      });

      describe('linked work item is rendered in a modal and has linked items', () => {
        beforeEach(async () => {
          createComponent({
            isModal: true,
            handler,
            workItemsMvc2Enabled: true,
            linkedWorkItemsEnabled: true,
          });

          await waitForPromises();
        });

        it('does not render a new modal', () => {
          expect(findModal().exists()).toBe(false);
        });

        it('emits `update-modal` when `show-modal` is emitted', async () => {
          const event = {
            preventDefault: jest.fn(),
          };

          findWorkItemRelationships().vm.$emit('showModal', {
            event,
            modalWorkItem: { id: 'childWorkItemId' },
          });
          await waitForPromises();

          expect(wrapper.emitted('update-modal')).toBeDefined();
        });
      });
    });
  });

  describe('notes widget', () => {
    it('renders notes by default', async () => {
      createComponent();
      await waitForPromises();

      const { confidential } = workItemQueryResponse.data.workspace.workItems.nodes[0];

      expect(findNotesWidget().exists()).toBe(true);
      expect(findNotesWidget().props('isWorkItemConfidential')).toBe(confidential);
    });
  });

  it('renders created/updated', async () => {
    createComponent();
    await waitForPromises();

    expect(findCreatedUpdated().exists()).toBe(true);
  });

  describe('abuse category selector', () => {
    beforeEach(async () => {
      setWindowLocation('?work_item_id=2');
      createComponent();
      await waitForPromises();
    });

    it('should not be visible by default', () => {
      expect(findAbuseCategorySelector().exists()).toBe(false);
    });

    it('should be visible when the work item modal emits `openReportAbuse` event', async () => {
      findModal().vm.$emit('openReportAbuse', mockWorkItemCommentNote);

      await nextTick();

      expect(findAbuseCategorySelector().exists()).toBe(true);

      findAbuseCategorySelector().vm.$emit('close-drawer');

      await nextTick();

      expect(findAbuseCategorySelector().exists()).toBe(false);
    });
  });

  describe('todos widget', () => {
    beforeEach(async () => {
      isLoggedIn.mockReturnValue(false);
      createComponent();
      await waitForPromises();
    });

    it('does not renders if not logged in', () => {
      expect(findWorkItemTodos().exists()).toBe(false);
    });
  });

  describe('work item attributes wrapper', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the work item attributes wrapper', () => {
      expect(findWorkItemAttributesWrapper().exists()).toBe(true);
    });

    it('shows an error message when it emits an `error` event', async () => {
      const updateError = 'Failed to update';

      findWorkItemAttributesWrapper().vm.$emit('error', updateError);
      await waitForPromises();

      expect(findAlert().text()).toBe(updateError);
    });
  });

  describe('work item two column view', () => {
    describe('when `workItemsBeta` is false', () => {
      beforeEach(async () => {
        createComponent({ workItemsBeta: false });
        await waitForPromises();
      });

      it('does not have the `work-item-overview` class', () => {
        expect(findWorkItemTwoColumnViewContainer().classes()).not.toContain('work-item-overview');
      });

      it('does not have sticky header component', () => {
        expect(findStickyHeader().exists()).toBe(false);
      });

      it('does not have right sidebar', () => {
        expect(findRightSidebar().exists()).toBe(false);
      });
    });

    describe('when `workItemsBeta` is true', () => {
      beforeEach(async () => {
        createComponent({ workItemsBeta: true });
        await waitForPromises();
      });

      it('has the `work-item-overview` class', () => {
        expect(findWorkItemTwoColumnViewContainer().classes()).toContain('work-item-overview');
      });

      it('renders the work item sticky header component', () => {
        expect(findStickyHeader().exists()).toBe(true);
      });

      it('has the right sidebar', () => {
        expect(findRightSidebar().exists()).toBe(true);
      });
    });
  });

  describe('edit button for work item title and description', () => {
    describe('when `workItemsBeta` is false', () => {
      beforeEach(async () => {
        createComponent({ workItemsBeta: false });
        await waitForPromises();
      });

      it('does not show the edit button', () => {
        expect(findEditButton().exists()).toBe(false);
      });

      it('renders the work item title inline editable component', () => {
        expect(findWorkItemTitle().exists()).toBe(true);
      });

      it('does not render the work item title with edit component', () => {
        expect(findWorkItemTitleWithEdit().exists()).toBe(false);
      });
    });

    describe('when `workItemsBeta` is true', () => {
      describe('with permissions to update', () => {
        beforeEach(async () => {
          createComponent({ workItemsBeta: true });
          await waitForPromises();
        });

        it('shows the edit button', () => {
          expect(findEditButton().exists()).toBe(true);
        });

        it('does not render the work item title inline editable component', () => {
          expect(findWorkItemTitle().exists()).toBe(false);
        });

        it('renders the work item title with edit component', () => {
          expect(findWorkItemTitleWithEdit().exists()).toBe(true);
          expect(findWorkItemTitleWithEdit().props('isEditing')).toBe(false);
        });

        it('work item description is not shown in edit mode by default', () => {
          expect(findWorkItemDescription().props('editMode')).toBe(false);
        });

        describe('when edit is clicked', () => {
          beforeEach(async () => {
            findEditButton().vm.$emit('click');
            await nextTick();
          });

          it('work item title component shows in edit mode', () => {
            expect(findWorkItemTitleWithEdit().props('isEditing')).toBe(true);
          });

          it('work item description component shows in edit mode', () => {
            expect(findWorkItemDescription().props('disableInlineEditing')).toBe(true);
            expect(findWorkItemDescription().props('editMode')).toBe(true);
          });
        });
      });

      describe('without permissions', () => {
        it('does not show edit button when user does not have the permissions for it', async () => {
          createComponent({ handler: successHandlerWithNoPermissions });
          await waitForPromises();
          expect(findEditButton().exists()).toBe(false);
        });
      });
    });
  });
});
