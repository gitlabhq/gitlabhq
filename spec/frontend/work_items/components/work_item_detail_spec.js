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
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemDueDate from '~/work_items/components/work_item_due_date.vue';
import WorkItemState from '~/work_items/components/work_item_state.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { i18n } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemDatesSubscription from '~/work_items/graphql/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import workItemAssigneesSubscription from '~/work_items/graphql/work_item_assignees.subscription.graphql';
import workItemMilestoneSubscription from '~/work_items/graphql/work_item_milestone.subscription.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateWorkItemTaskMutation from '~/work_items/graphql/update_work_item_task.mutation.graphql';
import {
  mockParent,
  workItemDatesSubscriptionResponse,
  workItemResponseFactory,
  workItemTitleSubscriptionResponse,
  workItemAssigneesSubscriptionResponse,
  workItemMilestoneSubscriptionResponse,
  projectWorkItemResponse,
  objectiveType,
} from '../mock_data';

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryResponseWithoutParent = workItemResponseFactory({
    parent: null,
    canUpdate: true,
    canDelete: true,
  });
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const successByIidHandler = jest.fn().mockResolvedValue(projectWorkItemResponse);
  const datesSubscriptionHandler = jest.fn().mockResolvedValue(workItemDatesSubscriptionResponse);
  const titleSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);
  const milestoneSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemMilestoneSubscriptionResponse);
  const assigneesSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemAssigneesSubscriptionResponse);
  const showModalHandler = jest.fn();

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);
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

  const createComponent = ({
    isModal = false,
    updateInProgress = false,
    workItemId = workItemQueryResponse.data.workItem.id,
    workItemIid = '1',
    handler = successHandler,
    subscriptionHandler = titleSubscriptionHandler,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
    error = undefined,
    workItemsMvcEnabled = false,
    workItemsMvc2Enabled = false,
    fetchByIid = false,
  } = {}) => {
    const handlers = [
      [workItemQuery, handler],
      [workItemTitleSubscription, subscriptionHandler],
      [workItemDatesSubscription, datesSubscriptionHandler],
      [workItemAssigneesSubscription, assigneesSubscriptionHandler],
      [workItemMilestoneSubscription, milestoneSubscriptionHandler],
      [workItemByIidQuery, successByIidHandler],
      confidentialityMock,
    ];

    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo(handlers),
      propsData: { isModal, workItemId, workItemIid },
      data() {
        return {
          updateInProgress,
          error,
        };
      },
      provide: {
        glFeatures: {
          workItemsMvc: workItemsMvcEnabled,
          workItemsMvc2: workItemsMvc2Enabled,
          useIidInWorkItemsPath: fetchByIid,
        },
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        fullPath: 'group/project',
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

  afterEach(() => {
    wrapper.destroy();
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
    const confidentialWorkItem = workItemResponseFactory({
      confidential: true,
    });

    // Mocks for work item without parent
    const withoutParentExpectedInputVars = {
      id: workItemQueryResponse.data.workItem.id,
      confidential: true,
    };
    const toggleConfidentialityWithoutParentHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: confidentialWorkItem.data.workItem,
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
      taskData: { id: workItemQueryResponse.data.workItem.id, confidential: true },
    };
    const toggleConfidentialityWithParentHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: {
            id: confidentialWorkItem.data.workItem.id,
            descriptionHtml: confidentialWorkItem.data.workItem.description,
          },
          task: {
            workItem: confidentialWorkItem.data.workItem,
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

        it('shows alert message when mutation fails', async () => {
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

    it('shows work item type if there is not a parent', async () => {
      createComponent({ handler: jest.fn().mockResolvedValue(workItemQueryResponseWithoutParent) });

      await waitForPromises();
      expect(findWorkItemType().exists()).toBe(true);
    });

    describe('with parent', () => {
      beforeEach(() => {
        const parentResponse = workItemResponseFactory(mockParent);
        createComponent({ handler: jest.fn().mockResolvedValue(parentResponse) });

        return waitForPromises();
      });

      it('shows secondary breadcrumbs if there is a parent', () => {
        expect(findParent().exists()).toBe(true);
      });

      it('does not show work item type', async () => {
        expect(findWorkItemType().exists()).toBe(false);
      });

      it('shows parent breadcrumb icon', () => {
        expect(findParentButton().props('icon')).toBe(mockParent.parent.workItemType.iconName);
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
        const parentResponse = workItemResponseFactory(mockParentObjective);
        createComponent({ handler: jest.fn().mockResolvedValue(parentResponse) });
        await waitForPromises();

        expect(findParentButton().attributes().href).toBe(mockParentObjective.parent.webUrl);
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

      expect(titleSubscriptionHandler).toHaveBeenCalledWith({
        issuableId: workItemQueryResponse.data.workItem.id,
      });
    });

    describe('assignees subscription', () => {
      describe('when the assignees widget exists', () => {
        it('calls the assignees subscription', async () => {
          createComponent();
          await waitForPromises();

          expect(assigneesSubscriptionHandler).toHaveBeenCalledWith({
            issuableId: workItemQueryResponse.data.workItem.id,
          });
        });
      });

      describe('when the assignees widget does not exist', () => {
        it('does not call the assignees subscription', async () => {
          const response = workItemResponseFactory({ assigneesWidgetPresent: false });
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

          expect(datesSubscriptionHandler).toHaveBeenCalledWith({
            issuableId: workItemQueryResponse.data.workItem.id,
          });
        });
      });

      describe('when the due date widget does not exist', () => {
        it('does not call the dates subscription', async () => {
          const response = workItemResponseFactory({ datesWidgetPresent: false });
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
          .mockResolvedValue(workItemResponseFactory({ assigneesWidgetPresent: false })),
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
      const response = workItemResponseFactory({ labelsWidgetPresent });
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
        const response = workItemResponseFactory({ datesWidgetPresent });
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
      const response = workItemResponseFactory({ milestoneWidgetPresent });
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

          expect(milestoneSubscriptionHandler).toHaveBeenCalledWith({
            issuableId: workItemQueryResponse.data.workItem.id,
          });
        });
      });

      describe('when the assignees widget does not exist', () => {
        it('does not call the milestone subscription', async () => {
          const response = workItemResponseFactory({ milestoneWidgetPresent: false });
          const handler = jest.fn().mockResolvedValue(response);
          createComponent({ handler });
          await waitForPromises();

          expect(milestoneSubscriptionHandler).not.toHaveBeenCalled();
        });
      });
    });
  });

  it('calls the global ID work item query when `useIidInWorkItemsPath` feature flag is false', async () => {
    createComponent();
    await waitForPromises();

    expect(successHandler).toHaveBeenCalledWith({
      id: workItemQueryResponse.data.workItem.id,
    });
    expect(successByIidHandler).not.toHaveBeenCalled();
  });

  it('calls the global ID work item query when `useIidInWorkItemsPath` feature flag is true but there is no `iid_path` parameter in URL', async () => {
    createComponent({ fetchByIid: true });
    await waitForPromises();

    expect(successHandler).toHaveBeenCalledWith({
      id: workItemQueryResponse.data.workItem.id,
    });
    expect(successByIidHandler).not.toHaveBeenCalled();
  });

  it('calls the IID work item query when `useIidInWorkItemsPath` feature flag is true and `iid_path` route parameter is present', async () => {
    setWindowLocation(`?iid_path=true`);

    createComponent({ fetchByIid: true, iidPathQueryParam: 'true' });
    await waitForPromises();

    expect(successHandler).not.toHaveBeenCalled();
    expect(successByIidHandler).toHaveBeenCalledWith({
      fullPath: 'group/project',
      iid: '1',
    });
  });

  it('calls the IID work item query when `useIidInWorkItemsPath` feature flag is true and `iid_path` route parameter is present and is a modal', async () => {
    setWindowLocation(`?iid_path=true`);

    createComponent({ fetchByIid: true, iidPathQueryParam: 'true', isModal: true });
    await waitForPromises();

    expect(successHandler).not.toHaveBeenCalled();
    expect(successByIidHandler).toHaveBeenCalledWith({
      fullPath: 'group/project',
      iid: '1',
    });
  });

  describe('hierarchy widget', () => {
    it('does not render children tree by default', async () => {
      createComponent();
      await waitForPromises();

      expect(findHierarchyTree().exists()).toBe(false);
    });

    describe('work item has children', () => {
      const objectiveWorkItem = workItemResponseFactory({
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
        createComponent({ handler });
        await waitForPromises();

        const event = {
          preventDefault: jest.fn(),
        };

        findHierarchyTree().vm.$emit('show-modal', event, { id: 'childWorkItemId' });
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

          findHierarchyTree().vm.$emit('show-modal', event, { id: 'childWorkItemId' });
          await waitForPromises();

          expect(wrapper.emitted('update-modal')).toBeDefined();
        });
      });
    });
  });

  describe('notes widget', () => {
    it('does not render notes by default', async () => {
      createComponent();
      await waitForPromises();

      expect(findNotesWidget().exists()).toBe(false);
    });

    it('renders notes when the work_items_mvc flag is on', async () => {
      const notesWorkItem = workItemResponseFactory({
        notesWidgetPresent: true,
      });
      const handler = jest.fn().mockResolvedValue(notesWorkItem);
      createComponent({ workItemsMvcEnabled: true, handler });
      await waitForPromises();

      expect(findNotesWidget().exists()).toBe(true);
    });
  });
});
