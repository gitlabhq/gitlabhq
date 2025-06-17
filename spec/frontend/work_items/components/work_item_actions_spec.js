import { GlDisclosureDropdown, GlModal, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';

import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { isLoggedIn } from '~/lib/utils/common_utils';
import toast from '~/vue_shared/plugins/global_toast';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemAbuseModal from '~/work_items/components/work_item_abuse_modal.vue';
import WorkItemStateToggle from '~/work_items/components/work_item_state_toggle.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import WorkItemChangeTypeModal from 'ee_else_ce/work_items/components/work_item_change_type_modal.vue';
import MoveWorkItemModal from '~/work_items/components/move_work_item_modal.vue';
import {
  STATE_OPEN,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_NAME_TASK,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateWorkItemNotificationsMutation from '~/work_items/graphql/update_work_item_notifications.mutation.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import convertWorkItemMutation from '~/work_items/graphql/work_item_convert.mutation.graphql';

import {
  convertWorkItemMutationErrorResponse,
  convertWorkItemMutationResponse,
  namespaceWorkItemTypesQueryResponse,
  updateWorkItemMutationResponse,
  updateWorkItemNotificationsMutationResponse,
} from 'ee_else_ce_jest/work_items/mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('WorkItemActions component', () => {
  Vue.use(VueApollo);

  let wrapper;
  const mockWorkItemReference = 'gitlab-org/gitlab-test#1';
  const mockWorkItemCreateNoteEmail =
    'gitlab-incoming+gitlab-org-gitlab-test-2-ddpzuq0zd2wefzofcpcdr3dg7-issue-1@gmail.com';

  const findModal = () => wrapper.findComponent(GlModal);
  const findConfidentialityToggleButton = () =>
    wrapper.findByTestId('confidentiality-toggle-action');
  const findLockDiscussionButton = () => wrapper.findByTestId('lock-action');
  const findDeleteButton = () => wrapper.findByTestId('delete-action');
  const findPromoteButton = () => wrapper.findByTestId('promote-action');
  const findCopyReferenceButton = () => wrapper.findByTestId('copy-reference-action');
  const findWorkItemToggleOption = () => wrapper.findComponent(WorkItemStateToggle);
  const findCopyCreateNoteEmailButton = () => wrapper.findByTestId('copy-create-note-email-action');
  const findReportAbuseButton = () => wrapper.findByTestId('report-abuse-action');
  const findSubmitAsSpamItem = () => wrapper.findByTestId('submit-as-spam-item');
  const findNewRelatedItemButton = () => wrapper.findByTestId('new-related-work-item');
  const findChangeTypeButton = () => wrapper.findByTestId('change-type-action');
  const findTruncationToggle = () => wrapper.findByTestId('truncation-toggle-action');
  const findSidebarToggle = () => wrapper.findByTestId('sidebar-toggle-action');
  const findReportAbuseModal = () => wrapper.findComponent(WorkItemAbuseModal);
  const findCreateWorkItemModal = () => wrapper.findComponent(CreateWorkItemModal);
  const findWorkItemChangeTypeModal = () => wrapper.findComponent(WorkItemChangeTypeModal);
  const findMoreDropdown = () => wrapper.findByTestId('work-item-actions-dropdown');
  const findMoreDropdownTooltip = () => getBinding(findMoreDropdown().element, 'gl-tooltip');
  const findDropdownItems = () =>
    wrapper.findAll(
      '[data-testid="work-item-actions-dropdown"] > *, [data-testid="work-item-actions-dropdown"] .gl-new-dropdown-item',
    );

  const findDropdownItemsActual = () =>
    findDropdownItems().wrappers.map((x) => {
      if (x.element.tagName === 'GL-DROPDOWN-DIVIDER-STUB') {
        return { divider: true };
      }

      if (x.element.tagName === 'GL-DISCLOSURE-DROPDOWN-GROUP-STUB') {
        return { group: true };
      }
      return {
        testId: x.attributes('data-testid'),
        text: x.text(),
      };
    });
  const findNotificationsToggle = () => wrapper.findByTestId('notifications-toggle-form');
  const findMoveButton = () => wrapper.findByTestId('move-action');
  const findMoveModal = () => wrapper.findComponent(MoveWorkItemModal);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const modalShowSpy = jest.fn();
  const $toast = {
    show: jest.fn(),
    hide: jest.fn(),
  };

  const typesQuerySuccessHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);
  const convertWorkItemMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(convertWorkItemMutationResponse);
  const convertWorkItemMutationErrorHandler = jest
    .fn()
    .mockResolvedValue(convertWorkItemMutationErrorResponse);
  const toggleNotificationsOffHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemNotificationsMutationResponse(false));
  const toggleNotificationsOnHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemNotificationsMutationResponse(true));
  const toggleNotificationsFailureHandler = jest
    .fn()
    .mockRejectedValue(new Error('Failed to subscribe'));
  const lockDiscussionMutationResolver = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);

  const createComponent = ({
    canUpdate = true,
    canUpdateMetadata = true,
    canDelete = true,
    canReportSpam = true,
    canMove = true,
    hasOkrsFeature = true,
    isConfidential = false,
    isDiscussionLocked = false,
    isGroup = false,
    isParentConfidential = false,
    okrsMvc = false,
    subscribedToNotifications = false,
    convertWorkItemMutationHandler = convertWorkItemMutationSuccessHandler,
    notificationsMutationHandler,
    lockDiscussionMutationHandler = lockDiscussionMutationResolver,
    workItemType = 'Task',
    workItemReference = mockWorkItemReference,
    workItemCreateNoteEmail = mockWorkItemCreateNoteEmail,
    hideSubscribe = undefined,
    hasChildren = false,
    canCreateRelatedItem = true,
    workItemsBeta = true,
    parentId = null,
    projectId = 'gid://gitlab/Project/1',
    namespaceFullName = 'GitLab.org / GitLab Test',
    updateInProgress = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemActions, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: createMockApollo([
        [namespaceWorkItemTypesQuery, typesQuerySuccessHandler],
        [convertWorkItemMutation, convertWorkItemMutationHandler],
        [updateWorkItemNotificationsMutation, notificationsMutationHandler],
        [updateWorkItemMutation, lockDiscussionMutationHandler],
      ]),
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        workItemState: STATE_OPEN,
        fullPath: 'gitlab-org/gitlab-test',
        workItemId: 'gid://gitlab/WorkItem/1',
        workItemIid: '1',
        workItemWebUrl: 'gitlab-org/gitlab-test/-/work_items/1',
        isGroup,
        canUpdate,
        canUpdateMetadata,
        canDelete,
        canReportSpam,
        canMove,
        isConfidential,
        isDiscussionLocked,
        subscribedToNotifications,
        isParentConfidential,
        workItemType,
        workItemReference,
        workItemCreateNoteEmail,
        hideSubscribe,
        hasChildren,
        canCreateRelatedItem,
        parentId,
        projectId,
        namespaceFullName,
        showSidebar: true,
        truncationEnabled: true,
        updateInProgress,
      },
      mocks: {
        $toast,
      },
      provide: {
        glFeatures: {
          okrsMvc,
          workItemsBeta,
        },
        hasOkrsFeature,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            show: jest.fn(),
          },
        }),
        GlDisclosureDropdownItem,
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: {
            close: modalShowSpy,
          },
        }),
        WorkItemChangeTypeModal: stubComponent(WorkItemChangeTypeModal, {
          methods: {
            show: jest.fn(),
          },
        }),
      },
    });
  };

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
  });

  it('renders modal', () => {
    createComponent();

    expect(findModal().props('visible')).toBe(false);
  });

  it('renders dropdown actions', async () => {
    createComponent({ workItemType: 'Issue' });

    await waitForPromises();

    expect(findDropdownItemsActual()).toEqual([
      {
        testId: 'notifications-toggle-form',
        text: 'Notifications',
      },
      {
        divider: true,
      },
      {
        testId: 'state-toggle-action',
        text: '',
      },
      {
        testId: 'new-related-work-item',
        text: 'New related item',
      },

      {
        testId: 'change-type-action',
        text: 'Change type',
      },
      {
        testId: 'move-action',
        text: 'Move',
      },
      {
        testId: 'lock-action',
        text: 'Lock discussion',
      },
      {
        testId: 'confidentiality-toggle-action',
        text: 'Turn on confidentiality',
      },
      {
        testId: 'copy-reference-action',
        text: 'Copy reference',
      },
      {
        testId: 'copy-create-note-email-action',
        text: 'Copy issue email address',
      },
      {
        group: true,
      },
      {
        testId: 'report-abuse-action',
        text: 'Report abuse',
      },
      {
        testId: 'submit-as-spam-item',
        text: 'Submit as spam',
      },
      {
        testId: 'delete-action',
        text: 'Delete issue',
      },
      {
        group: true,
      },
      {
        testId: 'truncation-toggle-action',
        text: 'Truncate descriptions',
      },
      {
        testId: 'sidebar-toggle-action',
        text: 'Hide sidebar',
      },
    ]);
  });

  it('renders "New related epic" instead of the default "New related item" when type is Epic', () => {
    createComponent({ workItemType: 'Epic' });

    expect(findDropdownItemsActual()).toEqual(
      expect.arrayContaining([
        {
          testId: 'new-related-work-item',
          text: 'New related epic',
        },
      ]),
    );
  });

  describe('lock discussion action', () => {
    it.each`
      isDiscussionLocked | buttonText
      ${false}           | ${'Lock discussion'}
      ${true}            | ${'Unlock discussion'}
    `('renders with text "$buttonText"', ({ isDiscussionLocked, buttonText }) => {
      createComponent({ isDiscussionLocked });

      expect(findLockDiscussionButton().text()).toBe(buttonText);
    });

    it.each`
      isDiscussionLocked | toastMessage
      ${false}           | ${'Discussion unlocked.'}
      ${true}            | ${'Discussion locked.'}
    `(
      'shows toast when clicked, with message "$toastMessage"',
      async ({ isDiscussionLocked, toastMessage }) => {
        createComponent({ isDiscussionLocked });

        findLockDiscussionButton().vm.$emit('action');
        await waitForPromises();

        expect(toast).toHaveBeenCalledWith(toastMessage);
      },
    );

    it('calls update mutation when clicked', async () => {
      createComponent();

      findLockDiscussionButton().vm.$emit('action');
      await waitForPromises();

      expect(lockDiscussionMutationResolver).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          notesWidget: {
            discussionLocked: true,
          },
        },
      });
    });

    it('emits error when update mutation fails', async () => {
      createComponent({
        lockDiscussionMutationHandler: jest.fn().mockRejectedValue(new Error('oh no!')),
      });

      findLockDiscussionButton().vm.$emit('action');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['oh no!']]);
    });
  });

  describe('toggle confidentiality action', () => {
    it.each`
      isConfidential | buttonText
      ${true}        | ${'Turn off confidentiality'}
      ${false}       | ${'Turn on confidentiality'}
    `(
      'renders confidentiality toggle button with text "$buttonText"',
      ({ isConfidential, buttonText }) => {
        createComponent({ isConfidential });

        expect(findConfidentialityToggleButton().text()).toBe(buttonText);
      },
    );

    it('emits `toggleWorkItemConfidentiality` event when clicked', async () => {
      createComponent();

      findConfidentialityToggleButton().vm.$emit('action');

      expect(wrapper.emitted('toggleWorkItemConfidentiality')[0]).toEqual([true]);

      await nextTick();
      expect(toast).toHaveBeenCalledWith('Confidentiality turned on.');
    });

    it('does not render when canUpdateMetadata is false', () => {
      createComponent({ canUpdateMetadata: false });
      expect(findConfidentialityToggleButton().exists()).toBe(false);
    });

    it('is disabled when item has confidential parent', () => {
      createComponent({ isParentConfidential: true });
      expect(findConfidentialityToggleButton().props('item')).toMatchObject({
        extraAttrs: { disabled: true },
      });
    });

    it('shows loading icon badge when the work item is confidential', () => {
      createComponent({ updateInProgress: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('delete action', () => {
    it('shows confirm modal with delete confirmation message when clicked', () => {
      createComponent();

      findDeleteButton().vm.$emit('action');

      expect(modalShowSpy).toHaveBeenCalled();
      expect(findModal().text()).toBe(
        'Are you sure you want to delete the task? This action cannot be reversed.',
      );
    });

    it('shows confirm modal with delete hierarchy confirmation message when clicked', () => {
      createComponent({ hasChildren: true });

      findDeleteButton().vm.$emit('action');

      expect(findModal().text()).toBe(
        'Delete this task and release all child items? This action cannot be reversed.',
      );
    });

    it('emits event when clicking OK button', () => {
      createComponent();

      findModal().vm.$emit('ok');

      expect(wrapper.emitted('deleteWorkItem')).toEqual([[]]);
    });

    it('does not render when canDelete is false', () => {
      createComponent({ canDelete: false });

      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('notifications action', () => {
    beforeEach(() => {
      createComponent();
      isLoggedIn.mockReturnValue(true);
    });

    it.each`
      scenario                                     | hideSubscribe
      ${'does not show notification subscription'} | ${true}
      ${'shows notification subscription'}         | ${false}
      ${'shows notification subscription'}         | ${undefined}
    `('$scenario when hideSubscribe is set to $hideSubscribe', ({ hideSubscribe }) => {
      createComponent({ hideSubscribe });
      expect(findNotificationsToggle().exists()).toBe(!hideSubscribe);
    });

    it.each`
      scenario        | subscribedToNotifications | notificationsMutationHandler     | subscribed | toastMessage
      ${'turned off'} | ${true}                   | ${toggleNotificationsOffHandler} | ${false}   | ${'Notifications turned off.'}
      ${'turned on'}  | ${false}                  | ${toggleNotificationsOnHandler}  | ${true}    | ${'Notifications turned on.'}
    `(
      'calls mutation and displays toast when notification toggle is $scenario',
      async ({
        subscribedToNotifications,
        notificationsMutationHandler,
        subscribed,
        toastMessage,
      }) => {
        createComponent({ notificationsMutationHandler, subscribedToNotifications });

        findNotificationsToggle().vm.$emit('action', !subscribedToNotifications);
        await waitForPromises();

        expect(notificationsMutationHandler).toHaveBeenCalledWith({
          input: {
            id: 'gid://gitlab/WorkItem/1',
            subscribed,
          },
        });
        expect(toast).toHaveBeenCalledWith(toastMessage);
      },
    );

    it('emits error when the update notification mutation fails', async () => {
      createComponent({ notificationsMutationHandler: toggleNotificationsFailureHandler });

      findNotificationsToggle().vm.$emit('action', false);
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Failed to subscribe']]);
    });
  });

  describe('promote action', () => {
    it.each`
      workItemType   | show
      ${'Task'}      | ${false}
      ${'Objective'} | ${false}
    `('does not show promote button for $workItemType', ({ workItemType, show }) => {
      createComponent({ workItemType });

      expect(findPromoteButton().exists()).toBe(show);
    });

    it('promote key result to objective', async () => {
      createComponent({ workItemType: 'Key Result' });
      await waitForPromises();

      expect(findPromoteButton().exists()).toBe(true);

      findPromoteButton().vm.$emit('action');
      await waitForPromises();

      expect(convertWorkItemMutationSuccessHandler).toHaveBeenCalled();
      expect($toast.show).toHaveBeenCalledWith('Promoted to objective.');
      expect(wrapper.emitted('promotedToObjective')).toEqual([[]]);
    });

    it('emits error when promote mutation fails', async () => {
      createComponent({
        workItemType: 'Key Result',
        convertWorkItemMutationHandler: convertWorkItemMutationErrorHandler,
      });
      await waitForPromises();

      expect(findPromoteButton().exists()).toBe(true);

      findPromoteButton().vm.$emit('action');
      await waitForPromises();

      expect(convertWorkItemMutationErrorHandler).toHaveBeenCalled();
      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while promoting the key result. Please try again.'],
      ]);
    });
  });

  describe('copy reference action', () => {
    it('shows toast when user clicks on the action', () => {
      createComponent();

      expect(findCopyReferenceButton().exists()).toBe(true);

      findCopyReferenceButton().vm.$emit('action');

      expect(toast).toHaveBeenCalledWith('Reference copied');
    });
  });

  describe('copy email address action', () => {
    it.each(['key result', 'objective'])(
      'renders correct button name when work item is %s',
      (workItemType) => {
        createComponent({ workItemType });

        expect(findCopyCreateNoteEmailButton().text()).toEqual(
          `Copy ${workItemType} email address`,
        );
      },
    );

    it('shows toast when user clicks on the action', () => {
      createComponent();

      expect(findCopyCreateNoteEmailButton().exists()).toBe(true);

      findCopyCreateNoteEmailButton().vm.$emit('action');

      expect(toast).toHaveBeenCalledWith('Email address copied');
    });
  });

  it('renders the toggle status button', () => {
    createComponent();

    expect(findWorkItemToggleOption().exists()).toBe(true);
  });

  describe('More actions menu', () => {
    it('renders the dropdown button', () => {
      createComponent();

      expect(findMoreDropdown().exists()).toBe(true);
    });

    it('renders tooltip', () => {
      createComponent();

      expect(findMoreDropdownTooltip().value).toBe('More actions');
    });
  });

  describe('report abuse action', () => {
    it('renders the report abuse button', () => {
      createComponent();

      expect(findReportAbuseButton().exists()).toBe(true);
      expect(findReportAbuseModal().exists()).toBe(false);
    });

    it('opens the report abuse modal', async () => {
      createComponent();

      findReportAbuseButton().vm.$emit('action');
      await nextTick();

      expect(wrapper.emitted('toggleReportAbuseModal')).toEqual([[true]]);
    });
  });

  describe('allowed work item types for modal', () => {
    describe('when group', () => {
      it('passes empty array', () => {
        createComponent({ isGroup: true });

        expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([]);
      });
    });

    describe('when okrs feature is not available', () => {
      it('passes default of incident, issue, and task', () => {
        createComponent({ hasOkrsFeature: false, okrsMvc: false });

        expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([
          WORK_ITEM_TYPE_NAME_INCIDENT,
          WORK_ITEM_TYPE_NAME_ISSUE,
          WORK_ITEM_TYPE_NAME_TASK,
        ]);
      });
    });

    describe('when okrs feature is available', () => {
      it('passes default of incident, issue, and task', () => {
        createComponent({ hasOkrsFeature: true, okrsMvc: true });

        expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([
          WORK_ITEM_TYPE_NAME_INCIDENT,
          WORK_ITEM_TYPE_NAME_ISSUE,
          WORK_ITEM_TYPE_NAME_TASK,
          WORK_ITEM_TYPE_NAME_KEY_RESULT,
          WORK_ITEM_TYPE_NAME_OBJECTIVE,
        ]);
      });
    });
  });

  describe('submit as spam item', () => {
    it('renders the "Submit as spam" action', () => {
      createComponent();

      expect(findSubmitAsSpamItem().props('item')).toEqual({
        href: 'gitlab-org/gitlab-test/-/issues/1/mark_as_spam',
        text: 'Submit as spam',
      });
    });

    it('does not render the "Submit as spam" action when not allowed', () => {
      createComponent({ canReportSpam: false });

      expect(findSubmitAsSpamItem().exists()).toBe(false);
    });
  });

  describe('new related item', () => {
    it('passes related item data to create work item modal', () => {
      createComponent();

      expect(findCreateWorkItemModal().props('namespaceFullName')).toBe('GitLab.org / GitLab Test');
      expect(findCreateWorkItemModal().props('relatedItem')).toEqual({
        id: 'gid://gitlab/WorkItem/1',
        reference: 'gitlab-org/gitlab-test#1',
        type: 'Task',
        webUrl: 'gitlab-org/gitlab-test/-/work_items/1',
      });
    });

    it('opens the create work item modal', async () => {
      createComponent({ workItemType: 'Task' });

      findNewRelatedItemButton().vm.$emit('action');
      await nextTick();

      expect(findCreateWorkItemModal().props('visible')).toBe(true);
    });

    it.each`
      isProjectSelectorVisible | workItemType
      ${false}                 | ${'Epic'}
      ${true}                  | ${'Issue'}
      ${true}                  | ${'Task'}
    `(
      'when workItemType is $workItemType, sets `CreateWorkItemModal` `showProjectSelector` prop to $isProjectSelectorVisible',
      ({ isProjectSelectorVisible, workItemType }) => {
        createComponent({ workItemType });

        expect(findCreateWorkItemModal().props('showProjectSelector')).toBe(
          isProjectSelectorVisible,
        );
      },
    );

    it('emits `workItemCreated` when `CreateWorkItemModal` emits `workItemCreated`', () => {
      createComponent();

      findCreateWorkItemModal().vm.$emit('workItemCreated');

      expect(wrapper.emitted('workItemCreated')).toHaveLength(1);
    });
  });

  describe('change type action', () => {
    it('opens the change type modal', () => {
      createComponent({ workItemType: 'Task' });

      findChangeTypeButton().vm.$emit('action');

      expect(findWorkItemChangeTypeModal().exists()).toBe(true);
    });

    it('hides the action in case of Epic type', () => {
      createComponent({ workItemType: 'Epic' });

      expect(findChangeTypeButton().exists()).toBe(false);
    });

    it('hides the action when there is no permission', () => {
      createComponent({ canUpdateMetadata: false });

      expect(findChangeTypeButton().exists()).toBe(false);
    });
  });

  it('passes the `parentId` prop down to the `WorkItemStateToggle` component', () => {
    createComponent({ parentId: 'example-id' });

    expect(findWorkItemToggleOption().props('parentId')).toBe('example-id');
  });

  describe('move issue button', () => {
    it('shows move button when workItemType is issue and `canMove` is true', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
      });
      await waitForPromises();

      expect(findMoveButton().exists()).toBe(true);
    });

    it('renders with text "Move"', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
      });

      await waitForPromises();

      expect(findMoveButton().text()).toBe('Move');
    });

    it('hides move button when `canMove` is false', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
        canMove: false,
      });
      await waitForPromises();

      expect(findMoveButton().exists()).toBe(false);
    });

    it('hides move button when workItemType is not issue', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_TASK,
      });

      await waitForPromises();

      expect(findMoveButton().exists()).toBe(false);
    });
  });

  describe('move modal', () => {
    it('does not render move modal when there is no projectId', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
        projectId: null,
      });

      await waitForPromises();

      expect(findMoveModal().exists()).toBe(false);
    });

    it('renders move modal when move button is clicked', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
      });

      await waitForPromises();

      findMoveButton().vm.$emit('action');
      await nextTick();

      expect(findMoveModal().exists()).toBe(true);
      expect(findMoveModal().props('visible')).toBe(true);
    });

    it('passes correct props to move modal', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
      });

      await waitForPromises();

      findMoveButton().vm.$emit('action');
      await nextTick();

      expect(findMoveModal().props()).toMatchObject({
        visible: true,
        workItemIid: '1',
        fullPath: 'gitlab-org/gitlab-test',
        projectId: 'gid://gitlab/Project/1',
      });
    });

    it('closes modal when hideModal event is emitted', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
      });

      await waitForPromises();

      findMoveButton().vm.$emit('action');
      await nextTick();

      findMoveModal().vm.$emit('hideModal');
      await nextTick();

      expect(findMoveModal().props('visible')).toBe(false);
    });
  });
  describe('view options', () => {
    it('toggles truncation enabled', () => {
      createComponent({ workItemType: 'Task' });

      expect(findTruncationToggle().exists()).toBe(true);

      findTruncationToggle().vm.$emit('action');

      expect(wrapper.emitted('toggleTruncationEnabled')).toEqual([[]]);
    });

    it('toggles sidebar visibility', () => {
      createComponent({ workItemType: 'Task' });

      expect(findSidebarToggle().exists()).toBe(true);

      findSidebarToggle().vm.$emit('action');
      expect(wrapper.emitted('toggleSidebar')).toEqual([[]]);
    });
  });
});
