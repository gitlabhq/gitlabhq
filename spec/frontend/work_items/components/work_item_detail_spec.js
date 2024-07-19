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
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import WorkItemTodos from '~/work_items/components/work_item_todos.vue';
import DesignWidget from '~/work_items/components/design_management/design_management_widget.vue';
import { i18n } from '~/work_items/constants';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';
import getAllowedWorkItemChildTypes from '~/work_items/graphql/work_item_allowed_children.query.graphql';

import {
  mockParent,
  workItemByIidResponseFactory,
  objectiveType,
  epicType,
  mockWorkItemCommentNote,
  mockBlockingLinkedItem,
  allowedChildrenTypesResponse,
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
  const workItemQueryResponseWithoutParent = workItemByIidResponseFactory({
    parent: null,
    canUpdate: true,
    canDelete: true,
  });
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const successHandlerWithNoPermissions = jest
    .fn()
    .mockResolvedValue(workItemQueryResponseWithNoPermissions);
  const showModalHandler = jest.fn();
  const { id } = workItemQueryResponse.data.workspace.workItem;
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });

  const allowedChildrenTypesHandler = jest.fn().mockResolvedValue(allowedChildrenTypesResponse);

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
  const findWorkItemDesigns = () => wrapper.findComponent(DesignWidget);
  const findDetailWrapper = () => wrapper.findByTestId('detail-wrapper');

  const createComponent = ({
    isGroup = false,
    isModal = false,
    isDrawer = false,
    updateInProgress = false,
    workItemIid = '1',
    handler = successHandler,
    mutationHandler,
    error = undefined,
    workItemsAlphaEnabled = false,
    workItemsBeta = false,
    namespaceLevelWorkItems = true,
    hasSubepicsFeature = true,
    router = true,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemDetail, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, handler],
        [updateWorkItemMutation, mutationHandler],
        [workItemUpdatedSubscription, workItemUpdatedSubscriptionHandler],
        [getAllowedWorkItemChildTypes, allowedChildrenTypesHandler],
      ]),
      isLoggedIn: isLoggedIn(),
      propsData: {
        isModal,
        workItemIid,
        isDrawer,
      },
      data() {
        return {
          updateInProgress,
          error,
        };
      },
      provide: {
        glFeatures: {
          workItemsAlpha: workItemsAlphaEnabled,
          workItemsBeta,
          namespaceLevelWorkItems,
        },
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasSubepicsFeature,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        fullPath: 'group/project',
        groupPath: 'group',
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
      mocks: {
        $router: router,
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

    it('does not fetch allowed children types for current work item', () => {
      expect(allowedChildrenTypesHandler).not.toHaveBeenCalled();
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
      expect(document.title).toEqual('Updated title (#1) · Task · test-project-path');
    });

    it('renders todos widget if logged in', () => {
      expect(findWorkItemTodos().exists()).toBe(true);
    });

    it('calls the work item updated subscription', () => {
      expect(workItemUpdatedSubscriptionHandler).toHaveBeenCalledWith({ id });
    });

    it('fetches allowed children types for current work item', async () => {
      createComponent();
      await waitForPromises();

      expect(allowedChildrenTypesHandler).toHaveBeenCalled();
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
          workItem: confidentialWorkItem.data.workspace.workItem,
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

    it('does not show ancestors widget if there is no parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();

      expect(findAncestors().exists()).toBe(false);
    });

    it('shows title in the header when there is no parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();
      expect(findWorkItemType().classes()).toEqual(['sm:!gl-block', 'gl-w-full']);
    });

    describe('`namespace_level_work_items` is disabled', () => {
      it('does not show ancestors widget and shows title in the header', async () => {
        createComponent({ namespaceLevelWorkItems: false });

        await waitForPromises();

        expect(findAncestors().exists()).toBe(false);
        expect(findWorkItemType().classes()).toEqual(['sm:!gl-block', 'gl-w-full']);
      });
    });

    describe('`subepics` is unavailable', () => {
      it('does not show ancestors widget and shows title in the header', async () => {
        const epicWorkItem = workItemByIidResponseFactory({
          workItemType: epicType,
        });
        const epicHandler = jest.fn().mockResolvedValue(epicWorkItem);

        createComponent({ hasSubepicsFeature: false, handler: epicHandler });

        await waitForPromises();

        expect(findAncestors().exists()).toBe(false);
        expect(findWorkItemType().classes()).toEqual(['sm:!gl-block', 'gl-w-full']);
      });
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
        expect(findWorkItemType().classes()).toEqual(['sm:!gl-hidden', 'gl-mt-3']);
      });
    });
  });

  describe('when the work item query is unsuccessful', () => {
    describe('full view', () => {
      beforeEach(() => {
        const errorHandler = jest.fn().mockRejectedValue('Oops');
        createComponent({ handler: errorHandler });
        return waitForPromises();
      });

      it('does not show the work item detail wrapper', () => {
        expect(findDetailWrapper().exists()).toBe(false);
      });

      it('shows empty state with an error message', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().props('description')).toBe(i18n.fetchError);
      });

      it('does not render work item UI elements', () => {
        expect(findWorkItemType().exists()).toBe(false);
        expect(findWorkItemTitle().exists()).toBe(false);
        expect(findCreatedUpdated().exists()).toBe(false);
        expect(findWorkItemActions().exists()).toBe(false);
        expect(findWorkItemTwoColumnViewContainer().exists()).toBe(false);
      });
    });

    describe('modal view', () => {
      it('shows the modal close button', async () => {
        createComponent({
          isModal: true,
          handler: jest.fn().mockRejectedValue('Oops, problemo'),
          workItemsAlphaEnabled: true,
        });

        await waitForPromises();

        expect(findCloseButton().exists()).toBe(true);
        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().props('description')).toBe(i18n.fetchError);
      });
    });
  });

  it('shows an error message when WorkItemTitle emits an `error` event', async () => {
    createComponent();
    await waitForPromises();
    const updateError = 'Failed to update';

    findWorkItemTitle().vm.$emit('error', updateError);
    await waitForPromises();

    expect(findAlert().text()).toBe(updateError);
  });

  it('calls the work item query', async () => {
    createComponent();
    await waitForPromises();

    expect(successHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
  });

  it('skips calling the work item query when there is no workItemIid', async () => {
    createComponent({ workItemIid: null });
    await waitForPromises();

    expect(successHandler).not.toHaveBeenCalled();
  });

  it('calls the work item query when isModal=true', async () => {
    createComponent({ isModal: true });
    await waitForPromises();

    expect(successHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
  });

  describe('hierarchy widget', () => {
    it('does not render children tree by when widget is not present', async () => {
      const workItemWithoutHierarchy = workItemByIidResponseFactory({
        hierarchyWidgetPresent: false,
      });
      const handler = jest.fn().mockResolvedValue(workItemWithoutHierarchy);
      createComponent({ handler });

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

      it.each([true, false])(
        'passes hasChildren %s to WorkItemActions when `WorkItemTree` emits `childrenLoaded` %s',
        async (hasChildren) => {
          createComponent({ handler: objectiveHandler });
          await waitForPromises();

          await findHierarchyTree().vm.$emit('childrenLoaded', hasChildren);

          expect(findWorkItemActions().props('hasChildren')).toBe(hasChildren);
        },
      );

      it('renders a modal', async () => {
        createComponent({ handler: objectiveHandler });
        await waitForPromises();

        expect(findModal().exists()).toBe(true);
      });

      it('opens the modal with the child when `show-modal` is emitted', async () => {
        createComponent({ handler: objectiveHandler, workItemsAlphaEnabled: true });
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
            workItemsAlphaEnabled: true,
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
    it('does not render when no linkedItems present', async () => {
      const mockEmptyLinkedItems = workItemByIidResponseFactory({
        linkedItems: [],
      });
      const handler = jest.fn().mockResolvedValue(mockEmptyLinkedItems);

      createComponent({ handler });
      await waitForPromises();

      expect(findWorkItemRelationships().exists()).toBe(false);
    });

    describe('work item has children', () => {
      const mockWorkItemLinkedItem = workItemByIidResponseFactory({
        linkedItems: mockBlockingLinkedItem,
      });
      const handler = jest.fn().mockResolvedValue(mockWorkItemLinkedItem);

      it('renders relationship widget when work item has linked items', async () => {
        createComponent({ handler });
        await waitForPromises();

        expect(findWorkItemRelationships().exists()).toBe(true);
      });

      it('opens the modal with the linked item when `showModal` is emitted', async () => {
        createComponent({
          handler,
          workItemsAlphaEnabled: true,
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
            workItemsAlphaEnabled: true,
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

      const { confidential } = workItemQueryResponse.data.workspace.workItem;

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

  describe('design widget', () => {
    it('does not render if application has no router', async () => {
      createComponent({ router: false });
      await waitForPromises();

      expect(findWorkItemDesigns().exists()).toBe(false);
    });

    it('renders if work item has design widget', async () => {
      createComponent();
      await waitForPromises();

      expect(findWorkItemDesigns().exists()).toBe(true);
    });

    it('renders if within a drawer', async () => {
      createComponent({ isDrawer: true });
      await waitForPromises();

      expect(findWorkItemDesigns().exists()).toBe(true);
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
    beforeEach(async () => {
      createComponent();
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

  describe('work item sticky header', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('enables the edit mode when event `toggleEditMode` is emitted', async () => {
      findStickyHeader().vm.$emit('toggleEditMode');
      await nextTick();

      expect(findWorkItemDescription().props('editMode')).toBe(true);
    });

    it('sticky header is visible by default', () => {
      expect(findStickyHeader().exists()).toBe(true);
    });

    it('sticky header is not visible if is drawer view', async () => {
      createComponent({ isDrawer: true });
      await waitForPromises();

      expect(findStickyHeader().exists()).toBe(false);
    });
  });

  describe('edit button for work item title and description', () => {
    describe('with permissions to update', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('shows the edit button', () => {
        expect(findEditButton().exists()).toBe(true);
      });

      it('renders the work item title with edit component', () => {
        expect(findWorkItemTitle().exists()).toBe(true);
        expect(findWorkItemTitle().props('isEditing')).toBe(false);
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
          expect(findWorkItemTitle().props('isEditing')).toBe(true);
        });

        it('work item description component shows in edit mode', () => {
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
