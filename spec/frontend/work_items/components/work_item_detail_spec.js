import { GlAlert, GlEmptyState, GlIntersectionObserver, GlButton, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import toast from '~/vue_shared/plugins/global_toast';
import { createControlledMockApollo } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { useRealDate } from 'helpers/fake_date';
import WorkItemLoading from '~/work_items/components/work_item_loading.vue';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemAncestors from '~/work_items/components/work_item_ancestors/work_item_ancestors.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemLinkedResources from '~/work_items/components/work_item_linked_resources.vue';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import WorkItemErrorTracking from '~/work_items/components/work_item_error_tracking.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemAbuseModal from '~/work_items/components/work_item_abuse_modal.vue';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import DesignWidget from '~/work_items/components/design_management/design_management_widget.vue';
import DesignUploadButton from '~/work_items/components//design_management/upload_button.vue';
import WorkItemCreateBranchMergeRequestSplitButton from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_split_button.vue';
import DesignDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import uploadDesignMutation from '~/work_items/components/design_management/graphql/upload_design.mutation.graphql';
import { i18n, STATE_CLOSED, WIDGET_TYPE_MILESTONE } from '~/work_items/constants';
import workItemByIdQuery from '~/work_items/graphql/work_item_by_id.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';
import getAllowedWorkItemChildTypes from '~/work_items/graphql/work_item_allowed_children.query.graphql';
import workspacePermissionsQuery from '~/work_items/graphql/workspace_permissions.query.graphql';
import workItemLinkedItemsQuery from '~/work_items/graphql/work_item_linked_items.query.graphql';

import {
  workItemByIidResponseFactory,
  workItemQueryResponse,
  mockParent,
  workItemLinkedItemsResponse,
  objectiveType,
  epicType,
  mockBlockingLinkedItem,
  allowedChildrenTypesResponse,
  mockProjectPermissionsQueryResponse,
  mockUploadDesignMutationResponse,
  mockUploadSkippedDesignMutationResponse,
  mockUploadErrorDesignMutationResponse,
} from 'ee_else_ce_jest/work_items/mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/work_items/components/design_management/cache_updates');
jest.mock('~/vue_shared/plugins/global_toast');

describe('WorkItemDetail component', () => {
  let wrapper;
  let glIntersectionObserver;
  let mockApollo;

  Vue.use(VueApollo);

  const workItemByIidQueryResponse = workItemByIidResponseFactory({
    canUpdate: true,
    canDelete: true,
  });
  const workItemQueryResponseWithNoPermissions = workItemByIidResponseFactory({
    canUpdate: false,
    canDelete: false,
  });
  const workItemQueryResponseWithoutParent = workItemByIidResponseFactory({
    parent: null,
    canUpdate: true,
    canDelete: true,
  });
  const workItemByIdQueryHandler = jest.fn().mockReturnValue(workItemQueryResponse);
  const successHandler = jest.fn().mockReturnValue(workItemByIidQueryResponse);
  const successHandlerWithNoPermissions = jest
    .fn()
    .mockReturnValue(workItemQueryResponseWithNoPermissions);
  const { id } = workItemByIidQueryResponse.data.namespace.workItem;
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockReturnValue({ data: { workItemUpdated: null } });

  const allowedChildrenTypesSuccessHandler = jest
    .fn()
    .mockReturnValue(allowedChildrenTypesResponse);
  const workspacePermissionsAllowedHandler = jest
    .fn()
    .mockReturnValue(mockProjectPermissionsQueryResponse());
  const workspacePermissionsNotAllowedHandler = jest
    .fn()
    .mockReturnValue(
      mockProjectPermissionsQueryResponse({ createDesign: false, moveDesign: false }),
    );
  const uploadSuccessDesignMutationHandler = jest
    .fn()
    .mockReturnValue(mockUploadDesignMutationResponse);
  const uploadSkippedDesignMutationHandler = jest
    .fn()
    .mockReturnValue(mockUploadSkippedDesignMutationResponse);
  const uploadErrorDesignMutationHandler = jest
    .fn()
    .mockReturnValue(mockUploadErrorDesignMutationResponse);

  const workItemLinkedItemsSuccessHandler = () => workItemLinkedItemsResponse;

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
  const findErrorTrackingWidget = () => wrapper.findComponent(WorkItemErrorTracking);
  const findLinkedResourcesWidget = () => wrapper.findComponent(WorkItemLinkedResources);
  const findHierarchyTree = () => wrapper.findComponent(WorkItemTree);
  const findWorkItemRelationships = () => wrapper.findComponent(WorkItemRelationships);
  const findNotesWidget = () => wrapper.findComponent(WorkItemNotes);
  const findWorkItemAbuseModal = () => wrapper.findComponent(WorkItemAbuseModal);
  const findTodosToggle = () => wrapper.findComponent(TodosToggle);
  const findStickyHeader = () => wrapper.findComponent(WorkItemStickyHeader);
  const findWorkItemTwoColumnViewContainer = () => wrapper.findByTestId('work-item-overview');
  const findRightSidebar = () => wrapper.findByTestId('work-item-overview-right-sidebar');
  const findEditButton = () => wrapper.findByTestId('work-item-edit-form-button');
  const findWorkItemDesigns = () => wrapper.findComponent(DesignWidget);
  const findDesignUploadButton = () => wrapper.findComponent(DesignUploadButton);
  const findDetailWrapper = () => wrapper.findByTestId('detail-wrapper');
  const findDrawer = () => wrapper.findComponent(WorkItemDrawer);
  const findCreateMergeRequestSplitButton = () =>
    wrapper.findComponent(WorkItemCreateBranchMergeRequestSplitButton);
  const findDesignDropzone = () => wrapper.findComponent(DesignDropzone);
  const findWorkItemDetailInfo = () => wrapper.findByTestId('info-alert');
  const findShowSidebarButton = () => wrapper.findByTestId('work-item-show-sidebar-button');
  const findRootNode = () => wrapper.findByTestId('work-item-detail');
  const findRefetchAlert = () => wrapper.findByTestId('work-item-refetch-alert');

  const mockDragEvent = ({ types = ['Files'], files = [], items = [] }) => {
    return { dataTransfer: { types, files, items } };
  };

  const createComponent = ({
    props = {},
    provide = {},
    handler = successHandler,
    workItemByIdHandler = workItemByIdQueryHandler,
    mutationHandler,
    router = true,
    workspacePermissionsHandler = workspacePermissionsAllowedHandler,
    uploadDesignMutationHandler = uploadSuccessDesignMutationHandler,
    allowedChildrenTypesHandler = allowedChildrenTypesSuccessHandler,
    showSidebar = true,
    lastRealtimeUpdatedAt = new Date('2023-01-01T12:00:00.000Z'),
  } = {}) => {
    mockApollo = createControlledMockApollo([
      [workItemByIidQuery, handler],
      [workItemByIdQuery, workItemByIdHandler],
      [updateWorkItemMutation, mutationHandler],
      [workItemUpdatedSubscription, workItemUpdatedSubscriptionHandler],
      [getAllowedWorkItemChildTypes, allowedChildrenTypesHandler],
      [workspacePermissionsQuery, workspacePermissionsHandler],
      [uploadDesignMutation, uploadDesignMutationHandler],
      [workItemLinkedItemsQuery, workItemLinkedItemsSuccessHandler],
    ]);

    wrapper = shallowMountExtended(WorkItemDetail, {
      apolloProvider: mockApollo.apolloProvider,
      isLoggedIn: isLoggedIn(),
      propsData: {
        isDrawer: false,
        isModal: false,
        workItemFullPath: 'group/project',
        workItemId: '',
        workItemIid: '1',
        ...props,
      },
      data() {
        return {
          showSidebar,
          lastRealtimeUpdatedAt,
        };
      },
      provide: {
        groupPath: 'group',
        hasLinkedItemsEpicsFeature: true,
        hasSubepicsFeature: true,
        isGroup: false,
        ...provide,
      },
      stubs: {
        GlSprintf,
        WorkItemAncestors: true,
        WorkItemWeight: true,
        WorkItemIteration: true,
        WorkItemHealthStatus: true,
        WorkItemErrorTracking,
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

  it.each`
    isDrawer | expected
    ${true}  | ${true}
    ${false} | ${false}
  `('passes isDrawer prop to child component props', async ({ isDrawer, expected }) => {
    createComponent({ props: { isDrawer } });
    await mockApollo.resolveAll();

    expect(findWorkItemDescription().props('hideFullscreenMarkdownButton')).toBe(expected);
    expect(findNotesWidget().props('hideFullscreenMarkdownButton')).toBe(expected);
    expect(findNotesWidget().props('isDrawer')).toBe(expected);
  });

  describe('when there is no `workItemIid` prop', () => {
    beforeEach(async () => {
      createComponent({ props: { workItemIid: null } });
      await nextTick();
    });

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });

    it('skips the work item updated subscription', () => {
      expect(workItemUpdatedSubscriptionHandler).not.toHaveBeenCalled();
    });

    it('does not fetch allowed children types for current work item', () => {
      expect(allowedChildrenTypesSuccessHandler).not.toHaveBeenCalled();
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
    beforeEach(async () => {
      createComponent();
      await mockApollo.resolveAll();
    });

    it('does not render skeleton', () => {
      expect(findWorkItemLoading().exists()).toBe(false);
      expect(findWorkItemTitle().exists()).toBe(true);
    });

    it('updates the document title', () => {
      expect(document.title).toEqual('Updated _title_ (#1) · Task · test-project-path');
    });

    it('renders todos widget if logged in', () => {
      expect(findTodosToggle().exists()).toBe(true);
    });

    it('calls the work item updated subscription', () => {
      expect(workItemUpdatedSubscriptionHandler).toHaveBeenCalledWith({
        id,
        useWorkItemFeatures: false,
      });
    });

    it('fetches allowed children types for current work item', () => {
      expect(allowedChildrenTypesSuccessHandler).toHaveBeenCalled();
    });

    it('fetches and sets allowedChildTypes when workItem.id changes', async () => {
      wrapper.vm.workItem = { id: 'gid://gitlab/WorkItem/123' };

      await nextTick();

      expect(allowedChildrenTypesSuccessHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/WorkItem/123',
      });
    });

    it('handles Apollo error when fetching allowedChildTypes', async () => {
      const allowedChildrenTypesErrorHandler = jest.fn();

      createComponent({
        props: { workItemId: 'gid://gitlab/WorkItem/123' },
        allowedChildrenTypesHandler: allowedChildrenTypesErrorHandler,
      });

      await mockApollo.resolveQuery(workItemByIdQuery);
      await mockApollo.rejectQuery(getAllowedWorkItemChildTypes);
      await mockApollo.resolveQuery(workspacePermissionsQuery);
      await mockApollo.resolveQuery(workItemLinkedItemsQuery);

      expect(wrapper.vm.allowedChildTypes).toEqual([]);
    });

    it('passes `parentMilestone` prop to work item tree', () => {
      const { milestone } = workItemByIidQueryResponse.data.namespace.workItem.widgets.find(
        (widget) => widget.type === WIDGET_TYPE_MILESTONE,
      );

      expect(findHierarchyTree().props('parentMilestone')).toEqual(milestone);
    });

    it('renders error tracking widget', () => {
      expect(findErrorTrackingWidget().props()).toEqual({
        fullPath: 'group/project',
        iid: '1',
      });
    });
  });

  describe('close button', () => {
    describe('when isModal prop is false', () => {
      it('does not render', async () => {
        createComponent({ props: { isModal: false } });
        await mockApollo.resolveAll();

        expect(findCloseButton().exists()).toBe(false);
      });
    });

    describe('when isModal prop is true', () => {
      it('renders', async () => {
        createComponent({ props: { isModal: true } });
        await mockApollo.resolveAll();

        expect(findCloseButton().props('icon')).toBe('close');
        expect(findCloseButton().attributes('aria-label')).toBe('Close');
      });

      it('emits `close` event when clicked', async () => {
        createComponent({ props: { isModal: true } });
        await mockApollo.resolveAll();

        findCloseButton().vm.$emit('click');

        expect(wrapper.emitted('close')).toEqual([[]]);
      });
    });
  });

  describe('confidentiality', () => {
    const errorMessage = 'Mutation failed';
    const confidentialWorkItem = workItemByIidResponseFactory({ confidential: true });
    const mutationHandler = jest.fn().mockReturnValue({
      data: {
        workItemUpdate: {
          workItem: confidentialWorkItem.data.namespace.workItem,
          errors: [],
        },
      },
    });

    it('sends updateInProgress props to child component', async () => {
      createComponent({ mutationHandler });
      await mockApollo.resolveAll();

      findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
      await nextTick();

      expect(findWorkItemActions().props('updateInProgress')).toBe(true);
    });

    it('emits workItemUpdated when mutation is successful', async () => {
      createComponent({ mutationHandler });
      await mockApollo.resolveAll();

      findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
      await mockApollo.resolveMutation(updateWorkItemMutation);

      await nextTick();
      expect(toast).toHaveBeenCalledWith('Confidentiality turned on.');

      expect(wrapper.emitted('workItemUpdated')).toEqual([[{ confidential: true }]]);
      expect(mutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          confidential: true,
        },
        useWorkItemFeatures: false,
      });
    });

    it('shows an alert when mutation fails', async () => {
      createComponent({ mutationHandler: jest.fn() });
      await mockApollo.resolveAll();

      findWorkItemActions().vm.$emit('toggleWorkItemConfidentiality', true);
      await mockApollo.rejectMutation(updateWorkItemMutation, new Error(errorMessage));

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
      await mockApollo.resolveAll();

      expect(findWorkItemDescription().exists()).toBe(true);
    });

    it('calls clearDraft when description is successfully updated', async () => {
      const clearDraftSpy = jest.fn();
      const mutationHandler = jest.fn().mockReturnValue({
        data: {
          workItemUpdate: {
            workItem: workItemByIidQueryResponse.data.namespace.workItem,
            errors: [],
          },
        },
      });
      createComponent({ mutationHandler });
      await mockApollo.resolveAll();

      findWorkItemDescription().vm.$emit('updateWorkItem', { clearDraft: clearDraftSpy });
      await mockApollo.resolveMutation(updateWorkItemMutation);

      expect(clearDraftSpy).toHaveBeenCalled();
    });

    it('does not call clearDraft when description is unsuccessfully updated', async () => {
      const clearDraftSpy = jest.fn();
      const mutationHandler = jest.fn();
      createComponent({ mutationHandler });
      await mockApollo.resolveAll();

      findWorkItemDescription().vm.$emit('updateWorkItem', { clearDraft: clearDraftSpy });
      await mockApollo.rejectMutation(updateWorkItemMutation);

      expect(clearDraftSpy).not.toHaveBeenCalled();
    });
  });

  describe('ancestors widget', () => {
    it('does not show ancestors widget by default', () => {
      createComponent();

      expect(findAncestors().exists()).toBe(false);
    });

    it('does not show ancestors widget if there is no parent', async () => {
      createComponent({ handler: () => workItemQueryResponseWithoutParent });

      await mockApollo.resolveAll();

      expect(findAncestors().exists()).toBe(false);
    });

    it('shows title in the header when there is no parent', async () => {
      createComponent({ handler: () => workItemQueryResponseWithoutParent });

      await mockApollo.resolveAll();
      expect(findWorkItemType().classes()).toEqual(['@sm/panel:!gl-block', 'gl-w-full']);
    });

    describe('`subepics` is unavailable', () => {
      it('does not show ancestors widget and shows title in the header', async () => {
        const epicWorkItem = workItemByIidResponseFactory({
          workItemType: epicType,
        });
        const epicHandler = () => epicWorkItem;

        createComponent({ provide: { hasSubepicsFeature: false }, handler: epicHandler });

        await mockApollo.resolveAll();

        expect(findAncestors().exists()).toBe(false);
        expect(findWorkItemType().classes()).toEqual(['@sm/panel:!gl-block', 'gl-w-full']);
      });
    });

    describe('`linked_items_epics` is unavailable', () => {
      it('does not show linked items widget', async () => {
        const epicWorkItem = workItemByIidResponseFactory({
          workItemType: epicType,
        });
        const epicHandler = () => epicWorkItem;

        createComponent({ provide: { hasLinkedItemsEpicsFeature: false }, handler: epicHandler });

        await mockApollo.resolveAll();

        expect(findWorkItemRelationships().exists()).toBe(false);
      });
    });

    describe('with parent', () => {
      beforeEach(async () => {
        const parentResponse = workItemByIidResponseFactory(mockParent);
        createComponent({ handler: () => parentResponse });

        await mockApollo.resolveAll();
      });

      it('shows ancestors widget if there is a parent', () => {
        expect(findAncestors().exists()).toBe(true);
      });

      it('does not show title in the header when parent exists', () => {
        expect(findWorkItemType().classes()).toEqual(['@sm/panel:!gl-hidden', '!gl-mt-3']);
      });
    });

    describe('with inaccessible parent', () => {
      beforeEach(async () => {
        const parentResponse = workItemByIidResponseFactory({ parent: null, hasParent: true });
        createComponent({ handler: () => parentResponse });

        await mockApollo.resolveAll();
      });

      it('shows ancestors widget if there is a inaccessible parent', () => {
        expect(findAncestors().exists()).toBe(true);
      });

      it('does not show title in the header when parent exists', () => {
        expect(findWorkItemType().classes()).toEqual(['@sm/panel:!gl-hidden', '!gl-mt-3']);
      });
    });
  });

  describe('when the work item query is unsuccessful', () => {
    describe('full view', () => {
      beforeEach(async () => {
        const errorHandler = jest.fn();
        createComponent({ handler: errorHandler });
        await mockApollo.rejectQuery(workItemByIidQuery);
        await mockApollo.resolveQuery(getAllowedWorkItemChildTypes);
        await mockApollo.resolveQuery(workspacePermissionsQuery);
        await mockApollo.resolveQuery(workItemLinkedItemsQuery);
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
          props: { isModal: true },
          handler: jest.fn(),
        });

        await mockApollo.rejectQuery(workItemByIidQuery);
        await mockApollo.resolveQuery(getAllowedWorkItemChildTypes);
        await mockApollo.resolveQuery(workspacePermissionsQuery);
        await mockApollo.resolveQuery(workItemLinkedItemsQuery);

        expect(findCloseButton().exists()).toBe(true);
        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().props('description')).toBe(i18n.fetchError);
      });
    });
  });

  it('renders the resources widget', async () => {
    createComponent();
    await mockApollo.resolveAll();

    expect(findLinkedResourcesWidget().exists()).toBe(true);
  });

  it('shows an error message when WorkItemTitle emits an `error` event', async () => {
    createComponent();
    await mockApollo.resolveAll();
    const updateError = 'Failed to update';

    findWorkItemTitle().vm.$emit('error', updateError);
    await waitForPromises();

    expect(findAlert().text()).toBe(updateError);
  });

  it('calls the work item query', async () => {
    createComponent();
    await mockApollo.resolveAll();

    expect(successHandler).toHaveBeenCalledWith(
      expect.objectContaining({ fullPath: 'group/project', iid: '1' }),
    );
  });

  it('calls the work item query by workItemId', async () => {
    const workItemId = workItemQueryResponse.data.workItem.id;
    createComponent({ props: { workItemId } });
    await mockApollo.resolveQuery(workItemByIdQuery);
    await mockApollo.resolveQuery(getAllowedWorkItemChildTypes);
    await mockApollo.resolveQuery(workspacePermissionsQuery);
    await mockApollo.resolveQuery(workItemLinkedItemsQuery);

    expect(workItemByIdQueryHandler).toHaveBeenCalledWith(
      expect.objectContaining({ id: workItemId }),
    );
    expect(successHandler).not.toHaveBeenCalled();
  });

  it('skips calling the work item query when there is no workItemIid and no workItemId', async () => {
    createComponent({ props: { workItemIid: null, workItemId: null } });
    await nextTick();

    expect(successHandler).not.toHaveBeenCalled();
  });

  it('calls the work item query when isModal=true', async () => {
    createComponent({ props: { isModal: true } });
    await mockApollo.resolveAll();

    expect(successHandler).toHaveBeenCalledWith(
      expect.objectContaining({ fullPath: 'group/project', iid: '1' }),
    );
  });

  describe('hierarchy widget', () => {
    it('does not render children tree by when widget is not present', async () => {
      const workItemWithoutHierarchy = workItemByIidResponseFactory({
        hierarchyWidgetPresent: false,
      });
      const handler = () => workItemWithoutHierarchy;
      createComponent({ handler });

      await mockApollo.resolveAll();

      expect(findHierarchyTree().exists()).toBe(false);
    });

    describe('work item has children', () => {
      const objectiveWorkItem = workItemByIidResponseFactory({
        workItemType: objectiveType,
        confidential: true,
      });
      const objectiveHandler = () => objectiveWorkItem;
      const objectiveNoChildrenHandler = () =>
        workItemByIidResponseFactory({
          workItemType: objectiveType,
          confidential: true,
          hasChildren: false,
        });

      const epicWorkItem = workItemByIidResponseFactory({
        workItemType: epicType,
      });
      const epicHandler = () => epicWorkItem;

      it.each`
        type           | handler
        ${'Objective'} | ${objectiveHandler}
        ${'Epic'}      | ${epicHandler}
      `('renders children tree when work item type is $type', async ({ handler }) => {
        createComponent({ handler });
        await mockApollo.resolveAll();

        expect(findHierarchyTree().exists()).toBe(true);
      });

      it.each`
        context             | handler                       | result
        ${'no child items'} | ${objectiveNoChildrenHandler} | ${false}
        ${'child items'}    | ${objectiveHandler}           | ${true}
      `(
        'sets the prop `hasChildren` to $result for WorkItemActions when there are $context',
        async ({ handler, result }) => {
          createComponent({ handler });
          await mockApollo.resolveAll();

          expect(findWorkItemActions().props('hasChildren')).toBe(result);
        },
      );

      it('opens the drawer with the child when `show-modal` is emitted', async () => {
        createComponent({ handler: objectiveHandler });
        await mockApollo.resolveAll();

        const event = {
          preventDefault: jest.fn(),
        };
        const modalWorkItem = { id: 'childWorkItemId' };

        findHierarchyTree().vm.$emit('show-modal', {
          event,
          modalWorkItem,
        });
        await nextTick();

        expect(findDrawer().props('activeItem')).toEqual(modalWorkItem);
      });

      it('closes the drawer when `close-drawer` is emitted from the selected work item', async () => {
        createComponent({ handler: objectiveHandler });
        await mockApollo.resolveAll();

        const event = {
          preventDefault: jest.fn(),
        };
        const modalWorkItem = { id: 'childWorkItemId' };

        findHierarchyTree().vm.$emit('show-modal', {
          event,
          modalWorkItem,
        });
        await nextTick();

        findHierarchyTree().vm.$emit('show-modal', {
          event,
          modalWorkItem,
        });
        await nextTick();

        expect(findDrawer().props('activeItem')).toEqual(null);
      });

      it('closes the drawer when `show-modal` is emitted with `null`', async () => {
        createComponent({ handler: objectiveHandler });
        await mockApollo.resolveAll();
        const event = {
          preventDefault: jest.fn(),
        };
        const modalWorkItem = { id: 'childWorkItemId' };
        findHierarchyTree().vm.$emit('show-modal', {
          event,
          modalWorkItem,
        });
        await nextTick();

        expect(findDrawer().props('activeItem')).toEqual(modalWorkItem);

        findHierarchyTree().vm.$emit('show-modal', {
          event,
          modalWorkItem: null,
        });
        await nextTick();

        expect(findDrawer().props('activeItem')).toEqual(null);
      });

      describe('work item is rendered in a modal and has children', () => {
        beforeEach(async () => {
          createComponent({
            props: { isModal: true },
            handler: objectiveHandler,
          });

          await mockApollo.resolveAll();
        });

        it('emits `update-modal` when `show-modal` is emitted', async () => {
          const event = {
            preventDefault: jest.fn(),
          };

          findHierarchyTree().vm.$emit('show-modal', {
            event,
            modalWorkItem: { id: 'childWorkItemId' },
          });
          await nextTick();

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
      const handler = () => mockEmptyLinkedItems;

      createComponent({ handler });
      await mockApollo.resolveAll();

      expect(findWorkItemRelationships().exists()).toBe(false);
    });

    it('re-fetches workItem query when `WorkItemActions` emits `work-item-created` event', async () => {
      createComponent();

      await mockApollo.resolveAll();

      expect(successHandler).toHaveBeenCalledTimes(1);

      findWorkItemActions().vm.$emit('work-item-created');

      await mockApollo.resolveAll();

      expect(successHandler).toHaveBeenCalledTimes(2);
    });

    describe('work item has children', () => {
      const mockWorkItemLinkedItem = workItemByIidResponseFactory({
        linkedItems: mockBlockingLinkedItem,
      });
      const handler = () => mockWorkItemLinkedItem;

      it('renders relationship widget when work item has linked items', async () => {
        createComponent({ handler });
        await mockApollo.resolveAll();

        expect(findWorkItemRelationships().exists()).toBe(true);
      });

      it('opens the modal with the linked item when `showModal` is emitted', async () => {
        createComponent({
          handler,
        });
        await mockApollo.resolveAll();

        const event = {
          preventDefault: jest.fn(),
        };
        const modalWorkItem = { id: 'childWorkItemId' };

        findWorkItemRelationships().vm.$emit('showModal', {
          event,
          modalWorkItem,
        });
        await nextTick();

        expect(findDrawer().props('activeItem')).toEqual(modalWorkItem);
      });

      describe('linked work item is rendered in a modal and has linked items', () => {
        beforeEach(async () => {
          createComponent({
            props: { isModal: true },
            handler,
          });

          await mockApollo.resolveAll();
        });

        it('emits `update-modal` when `show-modal` is emitted', async () => {
          const event = {
            preventDefault: jest.fn(),
          };

          findWorkItemRelationships().vm.$emit('showModal', {
            event,
            modalWorkItem: { id: 'childWorkItemId' },
          });
          await nextTick();

          expect(wrapper.emitted('update-modal')).toBeDefined();
        });
      });
    });
  });

  describe('notes widget', () => {
    it('renders notes by default', async () => {
      createComponent();
      await mockApollo.resolveAll();

      const { confidential } = workItemByIidQueryResponse.data.namespace.workItem;

      expect(findNotesWidget().exists()).toBe(true);
      expect(findNotesWidget().props('isWorkItemConfidential')).toBe(confidential);
      expect(findNotesWidget().props('canCreateNote')).toBeDefined();
    });

    describe('comment templates', () => {
      const mockCommentTemplatePaths = [
        {
          text: 'Your comment templates',
          href: '/-/profile/comment_templates',
          __typename: 'CommentTemplatePathType',
        },
        {
          text: 'Project comment templates',
          href: '/gitlab-org/gitlab-test/-/comment_templates',
          __typename: 'CommentTemplatePathType',
        },
        {
          text: 'Group comment templates',
          href: '/groups/gitlab-org/-/comment_templates',
          __typename: 'CommentTemplatePathType',
        },
      ];

      it('passes fetched comment template paths to WorkItemNotes component', async () => {
        const commentTemplateQueryResponse = workItemByIidResponseFactory({
          commentTemplatesPaths: mockCommentTemplatePaths,
        });

        const commentTemplateHandler = () => commentTemplateQueryResponse;

        createComponent({ handler: commentTemplateHandler });
        await mockApollo.resolveAll();

        expect(findNotesWidget().props('newCommentTemplatePaths')).toEqual(
          mockCommentTemplatePaths,
        );
      });
    });
  });

  it('renders created/updated', async () => {
    createComponent();
    await mockApollo.resolveAll();

    expect(findCreatedUpdated().exists()).toBe(true);
  });

  describe('abuse category selector', () => {
    beforeEach(async () => {
      setWindowLocation('?work_item_id=2');
      createComponent();
      await mockApollo.resolveAll();
    });

    it('should not be visible by default', () => {
      expect(findWorkItemAbuseModal().exists()).toBe(false);
    });

    it('should be visible when the work item actions button emits `toggleReportAbuseModal` event', async () => {
      findWorkItemActions().vm.$emit('toggleReportAbuseModal', true);
      await nextTick();

      expect(findWorkItemAbuseModal().exists()).toBe(true);

      findWorkItemAbuseModal().vm.$emit('close-modal');
      await nextTick();

      expect(findWorkItemAbuseModal().exists()).toBe(false);
    });
  });

  describe('work item change type', () => {
    beforeEach(async () => {
      createComponent();
      await mockApollo.resolveAll();
    });

    it('should call work item query on type change', async () => {
      findWorkItemActions().vm.$emit('workItemTypeChanged');
      await nextTick();

      expect(successHandler).toHaveBeenCalled();
    });
  });

  describe('todos widget', () => {
    beforeEach(async () => {
      isLoggedIn.mockReturnValue(false);
      createComponent();
      await mockApollo.resolveAll();
    });

    it('does not renders if not logged in', () => {
      expect(findTodosToggle().exists()).toBe(false);
    });
  });

  describe('design widget', () => {
    const file = new File(['foo'], 'foo.png', { type: 'image/png' });
    const fileList = [file];

    describe('when designs are not added and no versions exist', () => {
      it('renders the design dropzone when valid file is dragged and the Add design button is in viewport', async () => {
        createComponent();
        await mockApollo.resolveAll();

        glIntersectionObserver = wrapper.findComponent(GlIntersectionObserver);
        const dragEvent = mockDragEvent({
          types: ['Files', 'image'],
          items: [{ type: 'image/png' }],
        });

        findRootNode().trigger('dragenter', dragEvent);
        glIntersectionObserver.vm.$emit('appear');
        await nextTick();

        findRootNode().trigger('dragover', dragEvent);
        glIntersectionObserver.vm.$emit('appear');
        await nextTick();

        expect(findDesignDropzone().exists()).toBe(true);
      });

      it('does not render the design dropzone if add design button is not in viewport', async () => {
        createComponent();
        await mockApollo.resolveAll();

        glIntersectionObserver = wrapper.findComponent(GlIntersectionObserver);
        const dragEvent = mockDragEvent({
          types: ['Files', 'image'],
          items: [{ type: 'image/png' }],
        });

        wrapper.trigger('dragenter', dragEvent);
        glIntersectionObserver.vm.$emit('disappear');
        await nextTick();

        wrapper.trigger('dragover', dragEvent);
        glIntersectionObserver.vm.$emit('disappear');
        await nextTick();

        expect(findDesignDropzone().exists()).toBe(false);
      });

      it('does not render the design dropzone when invalid file is dragged', async () => {
        createComponent();
        await mockApollo.resolveAll();

        const dragEvent = mockDragEvent({
          types: ['Files'],
          items: [{ type: 'text/plain' }],
        });

        wrapper.trigger('dragenter', dragEvent);
        await nextTick();

        expect(findDesignDropzone().exists()).toBe(false);
      });
    });

    it('does not render if application has no router', async () => {
      createComponent({ router: false });
      await mockApollo.resolveAll();

      expect(findWorkItemDesigns().exists()).toBe(false);
    });

    it('renders if work item has design widget', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDesigns().exists()).toBe(true);
      expect(findDesignUploadButton().exists()).toBe(true);
    });

    it('renders if within a drawer', async () => {
      createComponent({ props: { isDrawer: true } });
      await mockApollo.resolveAll();

      expect(findWorkItemDesigns().exists()).toBe(true);
    });

    it('does not render upload design button if user does not have permission to upload', async () => {
      createComponent({ workspacePermissionsHandler: workspacePermissionsNotAllowedHandler });
      await mockApollo.resolveAll();

      expect(findDesignUploadButton().exists()).toBe(false);
    });

    it('does not call permisisons query for a group work item', async () => {
      createComponent({
        provide: { isGroup: true },
        workspacePermissionsHandler: workspacePermissionsAllowedHandler,
      });
      await mockApollo.resolveQuery(workItemByIidQuery);
      await mockApollo.resolveQuery(getAllowedWorkItemChildTypes);
      await mockApollo.resolveQuery(workItemLinkedItemsQuery);

      expect(workspacePermissionsAllowedHandler).not.toHaveBeenCalled();
    });

    it('uploads a design', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDesigns().exists()).toBe(true);

      findDesignUploadButton().vm.$emit('upload', fileList);
      await nextTick();
      await mockApollo.resolveMutation(uploadDesignMutation);

      expect(uploadSuccessDesignMutationHandler).toHaveBeenCalled();
    });

    it('when upload is skipped', async () => {
      createComponent({ uploadDesignMutationHandler: uploadSkippedDesignMutationHandler });
      await mockApollo.resolveAll();

      findDesignUploadButton().vm.$emit('upload', fileList);
      await nextTick();
      await mockApollo.resolveMutation(uploadDesignMutation);

      expect(uploadSkippedDesignMutationHandler).toHaveBeenCalled();
      expect(findWorkItemDesigns().props('uploadError')).toContain('Upload skipped.');
    });

    it('when upload fails - dismisses error', async () => {
      createComponent({ uploadDesignMutationHandler: uploadErrorDesignMutationHandler });
      await mockApollo.resolveAll();

      findDesignUploadButton().vm.$emit('upload', fileList);
      await nextTick();
      await mockApollo.resolveMutation(uploadDesignMutation);

      expect(uploadErrorDesignMutationHandler).toHaveBeenCalled();
      expect(findWorkItemDesigns().props('uploadError')).toBe(
        'Error uploading a new design. Please try again.',
      );

      findWorkItemDesigns().vm.$emit('dismissError');
      await nextTick();
      expect(findWorkItemDesigns().props('uploadError')).toBe(null);
    });
  });

  describe('canPasteDesign', () => {
    it('sets `canPasteDesign` to true on work item notes focus event', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDesigns().props('canPasteDesign')).toBe(true);

      findNotesWidget().vm.$emit('focus');
      await nextTick();

      expect(findWorkItemDesigns().props('canPasteDesign')).toBe(false);
    });

    it('sets `canPasteDesign` to false on work item notes blur event', async () => {
      createComponent();
      await mockApollo.resolveAll();

      findNotesWidget().vm.$emit('focus');
      await nextTick();

      expect(findWorkItemDesigns().props('canPasteDesign')).toBe(false);

      findNotesWidget().vm.$emit('blur');
      await nextTick();

      expect(findWorkItemDesigns().props('canPasteDesign')).toBe(true);
    });
  });

  describe('work item dev widget create split button', () => {
    it('should not show the button by default', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(findCreateMergeRequestSplitButton().exists()).toBe(false);
    });

    it('should show the button when the widget is applicable', async () => {
      createComponent({
        handler: () =>
          workItemByIidResponseFactory({
            canUpdate: true,
            canDelete: true,
            developmentWidgetPresent: true,
          }),
      });
      await mockApollo.resolveAll();

      expect(findCreateMergeRequestSplitButton().exists()).toBe(true);
    });

    it('should not show the button when the work item is closed', async () => {
      createComponent({
        handler: () =>
          workItemByIidResponseFactory({
            canUpdate: true,
            canDelete: true,
            developmentWidgetPresent: true,
            state: STATE_CLOSED,
          }),
      });
      await mockApollo.resolveAll();

      expect(findCreateMergeRequestSplitButton().exists()).toBe(false);
    });
  });

  describe('work item attributes wrapper', () => {
    beforeEach(async () => {
      createComponent();
      await mockApollo.resolveAll();
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
      await mockApollo.resolveAll();
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
      await mockApollo.resolveAll();
    });

    it('enables the edit mode when event `toggleEditMode` is emitted', async () => {
      findStickyHeader().vm.$emit('toggleEditMode');
      await nextTick();

      expect(findWorkItemDescription().props('editMode')).toBe(true);
    });

    it('sticky header is visible by default', () => {
      expect(findStickyHeader().exists()).toBe(true);
    });

    it('sticky header is visible in drawer view', async () => {
      createComponent({ props: { isDrawer: true } });
      await mockApollo.resolveAll();

      expect(findStickyHeader().exists()).toBe(true);
    });
  });

  describe('edit button for work item title and description', () => {
    describe('with permissions to update', () => {
      beforeEach(async () => {
        createComponent();
        await mockApollo.resolveAll();
      });

      it('shows the edit button', () => {
        expect(findEditButton().exists()).toBe(true);
        expect(findEditButton().attributes('title')).toContain('Edit title and description');
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
        await mockApollo.resolveAll();
        expect(findEditButton().exists()).toBe(false);
      });
    });
  });

  describe('calculates correct isGroup prop for attributes wrapper', () => {
    it('equal to isGroup injection when provided', async () => {
      createComponent({ provide: { isGroup: true } });
      await mockApollo.resolveQuery(workItemByIidQuery);
      await mockApollo.resolveQuery(getAllowedWorkItemChildTypes);
      await mockApollo.resolveQuery(workItemLinkedItemsQuery);

      expect(findWorkItemAttributesWrapper().props('isGroup')).toBe(true);
    });
  });

  describe('work item parent id', () => {
    const parentId = 'gid://gitlab/Issue/1';

    it('passes the `parentWorkItemId` value down to the `WorkItemActions` component', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemActions().props('parentId')).toBe(parentId);
    });

    it('passes the `parentWorkItemId` value down to the `WorkItemNotes` component', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(findNotesWidget().props('parentId')).toBe(parentId);
    });
  });

  describe('displays flash message when resolves a discussion', () => {
    it('when it resolves one discussion', async () => {
      setWindowLocation('?resolves_discussion=1');

      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDetailInfo().text()).toBe('Resolved 1 discussion.');
    });

    it('when it resolves all discussions', async () => {
      setWindowLocation('?resolves_discussion=all');

      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDetailInfo().text()).toBe('Resolved all discussions.');
    });
  });

  describe('shows sidebar based on view options', () => {
    it('when sidebar is shown based on view options', async () => {
      createComponent({ showSidebar: true });
      await mockApollo.resolveAll();
      expect(findShowSidebarButton().exists()).toBe(false);
      expect(findRightSidebar().classes()).not.toContain('@md/panel:gl-hidden');
    });
    it('when sidebar is hidden based on view options', async () => {
      createComponent({ showSidebar: false });
      await mockApollo.resolveAll();
      expect(findShowSidebarButton().exists()).toBe(true);
      expect(findRightSidebar().classes()).toContain('@md/panel:gl-hidden');
    });
    it('when show sidebar button is used', async () => {
      createComponent({ showSidebar: false });
      await mockApollo.resolveAll();
      findShowSidebarButton().vm.$emit('click');
      expect(findRightSidebar().isVisible()).toBe(true);
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createComponent();
      await mockApollo.resolveAll();
    });

    describe('sidebar visibility tracking', () => {
      it('tracks when sidebar is toggled', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findWorkItemActions().vm.$emit('toggleSidebar');
        await nextTick();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'change_work_item_sidebar_visibility',
          {
            label: 'false',
          },
          undefined,
        );

        findWorkItemActions().vm.$emit('toggleSidebar');
        await nextTick();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'change_work_item_sidebar_visibility',
          {
            label: 'true',
          },
          undefined,
        );
      });

      it('tracks when show sidebar button is clicked', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        createComponent({ showSidebar: false });
        await mockApollo.resolveAll();

        findShowSidebarButton().vm.$emit('click');
        await nextTick();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'change_work_item_sidebar_visibility',
          {
            label: 'true',
          },
          undefined,
        );
      });
    });

    describe('description truncation tracking', () => {
      it('tracks when truncation setting is toggled', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findWorkItemActions().vm.$emit('toggleTruncationEnabled');
        await nextTick();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'change_work_item_description_truncation',
          {
            label: 'false',
          },
          undefined,
        );

        findWorkItemActions().vm.$emit('toggleTruncationEnabled');
        await nextTick();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'change_work_item_description_truncation',
          {
            label: 'true',
          },
          undefined,
        );
      });
    });
  });

  describe('when websocket is reconnecting', () => {
    useRealDate();

    it('refetches work item when `actioncable:reconnected` event is emitted', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(successHandler).toHaveBeenCalledTimes(1);

      document.dispatchEvent(new CustomEvent('actioncable:reconnected'));
      await mockApollo.resolveAll();

      expect(successHandler).toHaveBeenCalledTimes(2);
    });

    it('does not refetch work item if less than 5 minutes have passed since last fetch', async () => {
      createComponent({ lastRealtimeUpdatedAt: new Date() });
      await mockApollo.resolveAll();

      expect(successHandler).toHaveBeenCalledTimes(1);

      document.dispatchEvent(new CustomEvent('actioncable:reconnected'));
      await waitForPromises();

      expect(successHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('when refetching work item fails', () => {
    beforeEach(async () => {
      createComponent();
      await mockApollo.resolveAll();

      // refetch triggers a new query through the mock link, creating a pending operation
      // we then reject it to simulate a network error
      // unfortunately, calling refetch this way here is the only way to prevent Jest spec from failing
      // if we try refetching via user action, we cannot handle refetch Apollo error properly
      wrapper.vm.$apollo.queries.workItem.refetch().catch(() => {});
      await mockApollo.rejectQuery(workItemByIidQuery, new Error('Refetch failed'));
    });

    it('renders refetch alert', () => {
      expect(findRefetchAlert().exists()).toBe(true); // Just to ensure the test runs without errors
    });

    it('applies correct classes to refetch alert', () => {
      expect(findRefetchAlert().classes()).toEqual([
        'flash-container',
        'flash-container-page',
        'sticky',
      ]);
    });

    it('hides refetch alert when it is dismissed', async () => {
      findRefetchAlert().findComponent(GlAlert).vm.$emit('dismiss');
      await nextTick();

      expect(findRefetchAlert().exists()).toBe(false);
    });

    it('hides refetch alert on successful refetch', async () => {
      successHandler.mockReturnValueOnce(workItemByIidQueryResponse);
      findRefetchAlert().findComponent(GlButton).vm.$emit('click');
      await mockApollo.resolveAll();

      expect(findRefetchAlert().exists()).toBe(false);
    });
  });

  it('applied correct classes to refetch error banner in the drawer', async () => {
    createComponent({ props: { isDrawer: true } });
    await mockApollo.resolveAll();

    // refetch triggers a new query through the mock link, creating a pending operation
    // we then reject it to simulate a network error
    // unfortunately, calling refetch this way here is the only way to prevent Jest spec from failing
    // if we try refetching via user action, we cannot handle refetch Apollo error properly
    wrapper.vm.$apollo.queries.workItem.refetch().catch(() => {});
    await mockApollo.rejectQuery(workItemByIidQuery, new Error('Refetch failed'));

    expect(findRefetchAlert().classes()).toEqual(['gl-sticky', 'gl-top-0']);
  });

  describe.each([true, false])('when archived is %s', (archived) => {
    const mockResponse = workItemByIidResponseFactory({ archived });
    const mockHandler = () => mockResponse;

    it('passes correct props', async () => {
      createComponent({ handler: mockHandler });
      await mockApollo.resolveAll();

      expect(findStickyHeader().props('archived')).toBe(archived);
    });
  });

  describe('Enables edit mode based on `edit` query parameter', () => {
    it('enables edit mode when edit=true query parameter is present', async () => {
      setWindowLocation('?edit=true');

      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDescription().props('editMode')).toBe(true);
    });

    it('does not enable edit mode when edit query parameter is false', async () => {
      setWindowLocation('?edit=false');

      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDescription().props('editMode')).toBe(false);
    });

    it('does not enable edit mode when edit query parameter is not present', async () => {
      createComponent();
      await mockApollo.resolveAll();

      expect(findWorkItemDescription().props('editMode')).toBe(false);
    });
  });
});
