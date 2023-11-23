import { GlAlert, GlSkeletonLoader, GlButton, GlEmptyState } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import WorkItemTodos from '~/work_items/components/work_item_todos.vue';
import { i18n } from '~/work_items/constants';
import groupWorkItemByIidQuery from '~/work_items/graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateWorkItemTaskMutation from '~/work_items/graphql/update_work_item_task.mutation.graphql';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';

import {
  groupWorkItemByIidResponseFactory,
  mockParent,
  workItemByIidResponseFactory,
  objectiveType,
  mockWorkItemCommentNote,
  mockBlockingLinkedItem,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemByIidResponseFactory({ canUpdate: true, canDelete: true });
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
  const groupSuccessHandler = jest.fn().mockResolvedValue(groupWorkItemQueryResponse);
  const showModalHandler = jest.fn();
  const { id } = workItemQueryResponse.data.workspace.workItems.nodes[0];
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);
  const findCreatedUpdated = () => wrapper.findComponent(WorkItemCreatedUpdated);
  const findWorkItemDescription = () => wrapper.findComponent(WorkItemDescription);
  const findWorkItemAttributesWrapper = () => wrapper.findComponent(WorkItemAttributesWrapper);
  const findParent = () => wrapper.findByTestId('work-item-parent');
  const findParentButton = () => findParent().findComponent(GlButton);
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

  const createComponent = ({
    isGroup = false,
    isModal = false,
    updateInProgress = false,
    workItemIid = '1',
    handler = successHandler,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
    error = undefined,
    workItemsMvc2Enabled = false,
    linkedWorkItemsEnabled = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemDetail, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, handler],
        [groupWorkItemByIidQuery, groupSuccessHandler],
        [workItemUpdatedSubscription, workItemUpdatedSubscriptionHandler],
        confidentialityMock,
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
      expect(findSkeleton().exists()).toBe(true);
      expect(findWorkItemTitle().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render skeleton', () => {
      expect(findSkeleton().exists()).toBe(false);
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
    const confidentialWorkItem = workItemByIidResponseFactory({
      confidential: true,
    });
    const workItem = confidentialWorkItem.data.workspace.workItems.nodes[0];

    // Mocks for work item without parent
    const withoutParentExpectedInputVars = { id, confidential: true };
    const toggleConfidentialityWithoutParentHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem,
          errors: [],
        },
      },
    });
    const withoutParentHandlerMock = jest
      .fn()
      .mockResolvedValue(workItemQueryResponseWithoutParent);
    const confidentialityWithoutParentMock = [
      updateWorkItemMutation,
      toggleConfidentialityWithoutParentHandler,
    ];
    const confidentialityWithoutParentFailureMock = [
      updateWorkItemMutation,
      jest.fn().mockRejectedValue(new Error(errorMessage)),
    ];

    // Mocks for work item with parent
    const withParentExpectedInputVars = {
      id: mockParent.parent.id,
      taskData: { id, confidential: true },
    };
    const toggleConfidentialityWithParentHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: {
            id: workItem.id,
            descriptionHtml: workItem.description,
          },
          task: {
            workItem,
            confidential: true,
          },
          errors: [],
        },
      },
    });
    const confidentialityWithParentMock = [
      updateWorkItemTaskMutation,
      toggleConfidentialityWithParentHandler,
    ];
    const confidentialityWithParentFailureMock = [
      updateWorkItemTaskMutation,
      jest.fn().mockRejectedValue(new Error(errorMessage)),
    ];

    describe.each`
      context        | handlerMock                 | confidentialityMock                 | confidentialityFailureMock                 | inputVariables
      ${'no parent'} | ${withoutParentHandlerMock} | ${confidentialityWithoutParentMock} | ${confidentialityWithoutParentFailureMock} | ${withoutParentExpectedInputVars}
      ${'parent'}    | ${successHandler}           | ${confidentialityWithParentMock}    | ${confidentialityWithParentFailureMock}    | ${withParentExpectedInputVars}
    `(
      'when work item has $context',
      ({ handlerMock, confidentialityMock, confidentialityFailureMock, inputVariables }) => {
        it('sends updateInProgress props to child component', async () => {
          createComponent({
            handler: handlerMock,
            confidentialityMock,
          });

          await waitForPromises();

          findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);

          await nextTick();

          expect(findCreatedUpdated().props('updateInProgress')).toBe(true);
        });

        it('emits workItemUpdated when mutation is successful', async () => {
          createComponent({
            handler: handlerMock,
            confidentialityMock,
          });

          await waitForPromises();

          findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
          await waitForPromises();

          expect(wrapper.emitted('workItemUpdated')).toEqual([[{ confidential: true }]]);
          expect(confidentialityMock[1]).toHaveBeenCalledWith({
            input: inputVariables,
          });
        });

        it('shows an alert when mutation fails', async () => {
          createComponent({
            handler: handlerMock,
            confidentialityMock: confidentialityFailureMock,
          });

          await waitForPromises();
          findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
          await waitForPromises();
          expect(wrapper.emitted('workItemUpdated')).toBeUndefined();

          await nextTick();

          expect(findAlert().exists()).toBe(true);
          expect(findAlert().text()).toBe(errorMessage);
        });
      },
    );
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

  describe('secondary breadcrumbs', () => {
    it('does not show secondary breadcrumbs by default', () => {
      createComponent();

      expect(findParent().exists()).toBe(false);
    });

    it('does not show secondary breadcrumbs if there is not a parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();

      expect(findParent().exists()).toBe(false);
    });

    it('shows title in the header when there is no parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();
      expect(findWorkItemType().classes()).toEqual(['gl-w-full']);
    });

    describe('with parent', () => {
      beforeEach(() => {
        const parentResponse = workItemByIidResponseFactory(mockParent);
        createComponent({ handler: jest.fn().mockResolvedValue(parentResponse) });

        return waitForPromises();
      });

      it('shows secondary breadcrumbs if there is a parent', () => {
        expect(findParent().exists()).toBe(true);
      });

      it('shows parent breadcrumb icon', () => {
        expect(findParentButton().props('icon')).toBe(mockParent.parent.workItemType.iconName);
      });

      it('shows parent title and iid', () => {
        expect(findParentButton().text()).toBe(
          `${mockParent.parent.title} #${mockParent.parent.iid}`,
        );
      });

      it('sets the parent breadcrumb URL pointing to issue page when parent type is `Issue`', () => {
        expect(findParentButton().attributes().href).toBe('../../-/issues/5');
      });

      it('sets the parent breadcrumb URL based on parent webUrl when parent type is not `Issue`', async () => {
        const mockParentObjective = {
          parent: {
            ...mockParent.parent,
            workItemType: {
              id: mockParent.parent.workItemType.id,
              name: 'Objective',
              iconName: 'issue-type-objective',
            },
          },
        };
        const parentResponse = workItemByIidResponseFactory(mockParentObjective);
        createComponent({ handler: jest.fn().mockResolvedValue(parentResponse) });
        await waitForPromises();

        expect(findParentButton().attributes().href).toBe(mockParentObjective.parent.webUrl);
      });

      it('shows work item type and iid', () => {
        const { iid } = workItemQueryResponse.data.workspace.workItems.nodes[0];
        expect(findParent().text()).toContain(`#${iid}`);
      });

      it('does not show title in the header when parent exists', () => {
        expect(findWorkItemType().classes()).toEqual(['gl-sm-display-none!']);
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
      const handler = jest.fn().mockResolvedValue(objectiveWorkItem);

      it('renders children tree when work item is an Objective', async () => {
        createComponent({ handler });
        await waitForPromises();

        expect(findHierarchyTree().exists()).toBe(true);
      });

      it('renders a modal', async () => {
        createComponent({ handler });
        await waitForPromises();

        expect(findModal().exists()).toBe(true);
      });

      it('opens the modal with the child when `show-modal` is emitted', async () => {
        createComponent({ handler, workItemsMvc2Enabled: true });
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
            handler,
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
    describe('when `workItemsMvc2Enabled` is false', () => {
      beforeEach(async () => {
        createComponent({ workItemsMvc2Enabled: false });
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

    describe('when `workItemsMvc2Enabled` is true', () => {
      beforeEach(async () => {
        createComponent({ workItemsMvc2Enabled: true });
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
});
