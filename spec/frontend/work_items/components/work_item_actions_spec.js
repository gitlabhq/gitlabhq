import { GlDisclosureDropdown, GlModal, GlToggle, GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import namespaceWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/namespace_work_item_types.query.graphql.json';

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
import {
  STATE_OPEN,
  TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
  TEST_ID_COPY_REFERENCE_ACTION,
  TEST_ID_DELETE_ACTION,
  TEST_ID_LOCK_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  TEST_ID_PROMOTE_ACTION,
  TEST_ID_TOGGLE_ACTION,
  TEST_ID_REPORT_ABUSE,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateWorkItemNotificationsMutation from '~/work_items/graphql/update_work_item_notifications.mutation.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import convertWorkItemMutation from '~/work_items/graphql/work_item_convert.mutation.graphql';

import {
  convertWorkItemMutationResponse,
  convertWorkItemMutationErrorResponse,
  updateWorkItemMutationResponse,
  updateWorkItemNotificationsMutationResponse,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/vue_shared/plugins/global_toast');

describe('WorkItemActions component', () => {
  Vue.use(VueApollo);

  let wrapper;
  const mockWorkItemReference = 'gitlab-org/gitlab-test#1';
  const mockWorkItemCreateNoteEmail =
    'gitlab-incoming+gitlab-org-gitlab-test-2-ddpzuq0zd2wefzofcpcdr3dg7-issue-1@gmail.com';

  const findModal = () => wrapper.findComponent(GlModal);
  const findConfidentialityToggleButton = () =>
    wrapper.findByTestId(TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION);
  const findLockDiscussionButton = () => wrapper.findByTestId(TEST_ID_LOCK_ACTION);
  const findDeleteButton = () => wrapper.findByTestId(TEST_ID_DELETE_ACTION);
  const findPromoteButton = () => wrapper.findByTestId(TEST_ID_PROMOTE_ACTION);
  const findCopyReferenceButton = () => wrapper.findByTestId(TEST_ID_COPY_REFERENCE_ACTION);
  const findWorkItemToggleOption = () => wrapper.findComponent(WorkItemStateToggle);
  const findCopyCreateNoteEmailButton = () =>
    wrapper.findByTestId(TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION);
  const findReportAbuseButton = () => wrapper.findByTestId(TEST_ID_REPORT_ABUSE);
  const findReportAbuseModal = () => wrapper.findComponent(WorkItemAbuseModal);
  const findMoreDropdown = () => wrapper.findByTestId('work-item-actions-dropdown');
  const findMoreDropdownTooltip = () => getBinding(findMoreDropdown().element, 'gl-tooltip');
  const findDropdownItems = () => wrapper.findAll('[data-testid="work-item-actions-dropdown"] > *');
  const findDropdownItemsActual = () =>
    findDropdownItems().wrappers.map((x) => {
      if (x.element.tagName === 'GL-DROPDOWN-DIVIDER-STUB') {
        return { divider: true };
      }

      return {
        testId: x.attributes('data-testid'),
        text: x.text(),
      };
    });
  const findNotificationsToggle = () => wrapper.findComponent(GlToggle);

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
    canDelete = true,
    isConfidential = false,
    isDiscussionLocked = false,
    subscribed = false,
    isParentConfidential = false,
    convertWorkItemMutationHandler = convertWorkItemMutationSuccessHandler,
    notificationsMutationHandler,
    lockDiscussionMutationHandler = lockDiscussionMutationResolver,
    workItemType = 'Task',
    workItemReference = mockWorkItemReference,
    workItemCreateNoteEmail = mockWorkItemCreateNoteEmail,
    hideSubscribe = undefined,
    hasChildren = false,
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
        canUpdate,
        canDelete,
        isConfidential,
        isDiscussionLocked,
        subscribed,
        isParentConfidential,
        workItemType,
        workItemReference,
        workItemCreateNoteEmail,
        hideSubscribe,
        hasChildren,
      },
      provide: {
        isGroup: false,
        glFeatures: { workItemsBeta: true, workItemsAlpha: true },
      },
      mocks: {
        $toast,
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

  it('renders dropdown actions', () => {
    createComponent();

    expect(findDropdownItemsActual()).toEqual([
      {
        testId: TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
        text: '',
      },
      {
        divider: true,
      },
      {
        testId: TEST_ID_TOGGLE_ACTION,
        text: '',
      },
      {
        testId: TEST_ID_LOCK_ACTION,
        text: 'Lock discussion',
      },
      {
        testId: TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
        text: 'Turn on confidentiality',
      },
      {
        testId: TEST_ID_COPY_REFERENCE_ACTION,
        text: 'Copy reference',
      },
      {
        testId: TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
        text: 'Copy task email address',
      },
      {
        divider: true,
      },
      {
        testId: TEST_ID_REPORT_ABUSE,
        text: 'Report abuse',
      },
      {
        testId: TEST_ID_DELETE_ACTION,
        text: 'Delete task',
      },
    ]);
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

    it('emits `toggleWorkItemConfidentiality` event when clicked', () => {
      createComponent();

      findConfidentialityToggleButton().vm.$emit('action');

      expect(wrapper.emitted('toggleWorkItemConfidentiality')[0]).toEqual([true]);
    });

    it.each`
      props                             | propName                  | value
      ${{ isParentConfidential: true }} | ${'isParentConfidential'} | ${true}
      ${{ canUpdate: false }}           | ${'canUpdate'}            | ${false}
    `('does not render when $propName is $value', ({ props }) => {
      createComponent(props);

      expect(findConfidentialityToggleButton().exists()).toBe(false);
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
      ${'turned off'} | ${false}                  | ${toggleNotificationsOffHandler} | ${false}   | ${'Notifications turned off.'}
      ${'turned on'}  | ${true}                   | ${toggleNotificationsOnHandler}  | ${true}    | ${'Notifications turned on.'}
    `(
      'calls mutation and displays toast when notification toggle is $scenario',
      async ({
        subscribedToNotifications,
        notificationsMutationHandler,
        subscribed,
        toastMessage,
      }) => {
        createComponent({ notificationsMutationHandler });

        findNotificationsToggle().vm.$emit('change', subscribedToNotifications);
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

      findNotificationsToggle().vm.$emit('change', false);
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
    createComponent();

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
});
