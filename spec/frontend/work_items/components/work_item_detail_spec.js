import {
  GlAlert,
  GlBadge,
  GlLoadingIcon,
  GlSkeletonLoader,
  GlButton,
  GlEmptyState,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { isLoggedIn } from '~/lib/utils/common_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import WorkItemDueDate from '~/work_items/components/work_item_due_date.vue';
import WorkItemState from '~/work_items/components/work_item_state.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import WorkItemTodos from '~/work_items/components/work_item_todos.vue';
import { i18n } from '~/work_items/constants';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemDatesSubscription from '~/graphql_shared/subscriptions/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import workItemAssigneesSubscription from '~/work_items/graphql/work_item_assignees.subscription.graphql';
import workItemMilestoneSubscription from '~/work_items/graphql/work_item_milestone.subscription.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateWorkItemTaskMutation from '~/work_items/graphql/update_work_item_task.mutation.graphql';

import {
  mockParent,
  workItemDatesSubscriptionResponse,
  workItemByIidResponseFactory,
  workItemTitleSubscriptionResponse,
  workItemAssigneesSubscriptionResponse,
  workItemMilestoneSubscriptionResponse,
  objectiveType,
  mockWorkItemCommentNote,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemByIidResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryResponseWithoutParent = workItemByIidResponseFactory({
    parent: null,
    canUpdate: true,
    canDelete: true,
  });
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const datesSubscriptionHandler = jest.fn().mockResolvedValue(workItemDatesSubscriptionResponse);
  const titleSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);
  const milestoneSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemMilestoneSubscriptionResponse);
  const assigneesSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemAssigneesSubscriptionResponse);
  const showModalHandler = jest.fn();
  const { id } = workItemQueryResponse.data.workspace.workItems.nodes[0];

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);
  const findCreatedUpdated = () => wrapper.findComponent(WorkItemCreatedUpdated);
  const findWorkItemState = () => wrapper.findComponent(WorkItemState);
  const findWorkItemDescription = () => wrapper.findComponent(WorkItemDescription);
  const findWorkItemDueDate = () => wrapper.findComponent(WorkItemDueDate);
  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssignees);
  const findWorkItemLabels = () => wrapper.findComponent(WorkItemLabels);
  const findWorkItemMilestone = () => wrapper.findComponent(WorkItemMilestone);
  const findParent = () => wrapper.find('[data-testid="work-item-parent"]');
  const findParentButton = () => findParent().findComponent(GlButton);
  const findCloseButton = () => wrapper.find('[data-testid="work-item-close"]');
  const findWorkItemType = () => wrapper.find('[data-testid="work-item-type"]');
  const findHierarchyTree = () => wrapper.findComponent(WorkItemTree);
  const findNotesWidget = () => wrapper.findComponent(WorkItemNotes);
  const findModal = () => wrapper.findComponent(WorkItemDetailModal);
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findWorkItemTodos = () => wrapper.findComponent(WorkItemTodos);

  const createComponent = ({
    isModal = false,
    updateInProgress = false,
    workItemId = id,
    workItemIid = '1',
    handler = successHandler,
    subscriptionHandler = titleSubscriptionHandler,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
    error = undefined,
    workItemsMvc2Enabled = false,
  } = {}) => {
    const handlers = [
      [workItemByIidQuery, handler],
      [workItemTitleSubscription, subscriptionHandler],
      [workItemDatesSubscription, datesSubscriptionHandler],
      [workItemAssigneesSubscription, assigneesSubscriptionHandler],
      [workItemMilestoneSubscription, milestoneSubscriptionHandler],
      confidentialityMock,
    ];

    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo(handlers),
      isLoggedIn: isLoggedIn(),
      propsData: { isModal, workItemId, workItemIid },
      data() {
        return {
          updateInProgress,
          error,
        };
      },
      provide: {
        glFeatures: {
          workItemsMvc2: workItemsMvc2Enabled,
        },
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        fullPath: 'group/project',
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

  describe('when there is no `workItemId` and no `workItemIid` prop', () => {
    beforeEach(() => {
      createComponent({ workItemId: null, workItemIid: null });
    });

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders skeleton loader', () => {
      expect(findSkeleton().exists()).toBe(true);
      expect(findWorkItemState().exists()).toBe(false);
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
      expect(findWorkItemState().exists()).toBe(true);
      expect(findWorkItemTitle().exists()).toBe(true);
    });

    it('updates the document title', () => {
      expect(document.title).toEqual('Updated title · Task · test-project-path');
    });

    it('renders todos widget if logged in', () => {
      expect(findWorkItemTodos().exists()).toBe(true);
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
        it('renders confidential badge when work item is confidential', async () => {
          createComponent({
            handler: jest.fn().mockResolvedValue(confidentialWorkItem),
            confidentialityMock,
          });

          await waitForPromises();

          const confidentialBadge = wrapper.findComponent(GlBadge);
          expect(confidentialBadge.exists()).toBe(true);
          expect(confidentialBadge.props()).toMatchObject({
            variant: 'warning',
            icon: 'eye-slash',
          });
          expect(confidentialBadge.attributes('title')).toBe(
            'Only project members with at least the Reporter role, the author, and assignees can view or be notified about this task.',
          );
          expect(confidentialBadge.text()).toBe('Confidential');
        });

        it('renders gl-loading-icon while update mutation is in progress', async () => {
          createComponent({
            handler: handlerMock,
            confidentialityMock,
          });

          await waitForPromises();

          findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);

          await nextTick();

          expect(findLoadingIcon().exists()).toBe(true);
        });

        it('emits workItemUpdated and shows confidentiality badge when mutation is successful', async () => {
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
          expect(findLoadingIcon().exists()).toBe(false);
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
          expect(findLoadingIcon().exists()).toBe(false);
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

    it('shows work item type with reference when there is no a parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();
      expect(findWorkItemType().exists()).toBe(true);
      expect(findWorkItemType().text()).toBe('Task #1');
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

      it('does not show work item type', () => {
        expect(findWorkItemType().exists()).toBe(false);
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
        expect(findParentButton().attributes().href).toBe('../../issues/5');
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
        const { iid, workItemType } = workItemQueryResponse.data.workspace.workItems.nodes[0];
        expect(findParent().text()).toContain(`${workItemType.name} #${iid}`);
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

  describe('subscriptions', () => {
    it('calls the title subscription', async () => {
      createComponent();
      await waitForPromises();

      expect(titleSubscriptionHandler).toHaveBeenCalledWith({ issuableId: id });
    });

    describe('assignees subscription', () => {
      describe('when the assignees widget exists', () => {
        it('calls the assignees subscription', async () => {
          createComponent();
          await waitForPromises();

          expect(assigneesSubscriptionHandler).toHaveBeenCalledWith({ issuableId: id });
        });
      });

      describe('when the assignees widget does not exist', () => {
        it('does not call the assignees subscription', async () => {
          const response = workItemByIidResponseFactory({ assigneesWidgetPresent: false });
          const handler = jest.fn().mockResolvedValue(response);
          createComponent({ handler });
          await waitForPromises();

          expect(assigneesSubscriptionHandler).not.toHaveBeenCalled();
        });
      });
    });

    describe('dates subscription', () => {
      describe('when the due date widget exists', () => {
        it('calls the dates subscription', async () => {
          createComponent();
          await waitForPromises();

          expect(datesSubscriptionHandler).toHaveBeenCalledWith({ issuableId: id });
        });
      });

      describe('when the due date widget does not exist', () => {
        it('does not call the dates subscription', async () => {
          const response = workItemByIidResponseFactory({ datesWidgetPresent: false });
          const handler = jest.fn().mockResolvedValue(response);
          createComponent({ handler });
          await waitForPromises();

          expect(datesSubscriptionHandler).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('assignees widget', () => {
    it('renders assignees component when widget is returned from the API', async () => {
      createComponent();
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(true);
    });

    it('does not render assignees component when widget is not returned from the API', async () => {
      createComponent({
        handler: jest
          .fn()
          .mockResolvedValue(workItemByIidResponseFactory({ assigneesWidgetPresent: false })),
      });
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(false);
    });
  });

  describe('labels widget', () => {
    it.each`
      description                                               | labelsWidgetPresent | exists
      ${'renders when widget is returned from API'}             | ${true}             | ${true}
      ${'does not render when widget is not returned from API'} | ${false}            | ${false}
    `('$description', async ({ labelsWidgetPresent, exists }) => {
      const response = workItemByIidResponseFactory({ labelsWidgetPresent });
      const handler = jest.fn().mockResolvedValue(response);
      createComponent({ handler });
      await waitForPromises();

      expect(findWorkItemLabels().exists()).toBe(exists);
    });
  });

  describe('dates widget', () => {
    describe.each`
      description                               | datesWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}            | ${true}
      ${'when widget is not returned from API'} | ${false}           | ${false}
    `('$description', ({ datesWidgetPresent, exists }) => {
      it(`${datesWidgetPresent ? 'renders' : 'does not render'} due date component`, async () => {
        const response = workItemByIidResponseFactory({ datesWidgetPresent });
        const handler = jest.fn().mockResolvedValue(response);
        createComponent({ handler });
        await waitForPromises();

        expect(findWorkItemDueDate().exists()).toBe(exists);
      });
    });

    it('shows an error message when it emits an `error` event', async () => {
      createComponent();
      await waitForPromises();
      const updateError = 'Failed to update';

      findWorkItemDueDate().vm.$emit('error', updateError);
      await waitForPromises();

      expect(findAlert().text()).toBe(updateError);
    });
  });

  describe('milestone widget', () => {
    it.each`
      description                                               | milestoneWidgetPresent | exists
      ${'renders when widget is returned from API'}             | ${true}                | ${true}
      ${'does not render when widget is not returned from API'} | ${false}               | ${false}
    `('$description', async ({ milestoneWidgetPresent, exists }) => {
      const response = workItemByIidResponseFactory({ milestoneWidgetPresent });
      const handler = jest.fn().mockResolvedValue(response);
      createComponent({ handler });
      await waitForPromises();

      expect(findWorkItemMilestone().exists()).toBe(exists);
    });

    describe('milestone subscription', () => {
      describe('when the milestone widget exists', () => {
        it('calls the milestone subscription', async () => {
          createComponent();
          await waitForPromises();

          expect(milestoneSubscriptionHandler).toHaveBeenCalledWith({ issuableId: id });
        });
      });

      describe('when the assignees widget does not exist', () => {
        it('does not call the milestone subscription', async () => {
          const response = workItemByIidResponseFactory({ milestoneWidgetPresent: false });
          const handler = jest.fn().mockResolvedValue(response);
          createComponent({ handler });
          await waitForPromises();

          expect(milestoneSubscriptionHandler).not.toHaveBeenCalled();
        });
      });
    });
  });

  it('calls the work item query', async () => {
    createComponent();
    await waitForPromises();

    expect(successHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
  });

  it('skips the work item query when there is no workItemIid', async () => {
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

  describe('notes widget', () => {
    it('renders notes by default', async () => {
      createComponent();
      await waitForPromises();

      expect(findNotesWidget().exists()).toBe(true);
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
});
