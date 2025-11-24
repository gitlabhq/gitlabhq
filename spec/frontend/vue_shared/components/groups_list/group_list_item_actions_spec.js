import { GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
import GroupListItemDeleteModal from '~/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import GroupListItemLeaveModal from '~/vue_shared/components/groups_list/group_list_item_leave_modal.vue';
import {
  ACTION_COPY_ID,
  ACTION_ARCHIVE,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
  ACTION_REQUEST_ACCESS,
  ACTION_WITHDRAW_ACCESS_REQUEST,
} from '~/vue_shared/components/list_actions/constants';
import { groups } from 'jest/vue_shared/components/groups_list/mock_data';
import { archiveGroup, restoreGroup, unarchiveGroup } from '~/api/groups_api';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  renderArchiveSuccessToast,
  renderRestoreSuccessToast,
  renderUnarchiveSuccessToast,
  renderDeleteSuccessToast,
} from '~/vue_shared/components/groups_list/utils';
import { createAlert } from '~/alert';
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import axios from '~/lib/utils/axios_utils';

const MOCK_DELETE_PARAMS = {
  testParam: true,
};

const mockToast = {
  show: jest.fn(),
};

jest.mock('~/vue_shared/components/groups_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/groups_list/utils'),
  renderRestoreSuccessToast: jest.fn(),
  renderArchiveSuccessToast: jest.fn(),
  renderUnarchiveSuccessToast: jest.fn(),
  renderDeleteSuccessToast: jest.fn(),
  deleteParams: jest.fn(() => MOCK_DELETE_PARAMS),
}));
jest.mock('~/alert');
jest.mock('~/api/groups_api');
jest.mock('~/lib/utils/copy_to_clipboard');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('GroupListItemActions', () => {
  let wrapper;
  let axiosMock;

  const [group] = groups;
  const defaultProps = { group };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(GroupListItemActions, {
      propsData: { ...defaultProps, ...propsData },
      mocks: {
        $toast: mockToast,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findListActions = () => wrapper.findComponent(ListActions);
  const findDeleteConfirmationModal = () => wrapper.findComponent(GroupListItemDeleteModal);
  const findPreventDeleteModal = () => wrapper.findComponent(GroupListItemPreventDeleteModal);
  const findLeaveModal = () => wrapper.findComponent(GroupListItemLeaveModal);

  const fireAction = async (action) => {
    findListActions().props('actions')[action].action();
    await nextTick();
  };
  const deleteModalFireConfirmEvent = async () => {
    findDeleteConfirmationModal().vm.$emit('confirm', {
      preventDefault: jest.fn(),
    });
    await nextTick();
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays actions dropdown', () => {
      expect(findListActions().props()).toMatchObject({
        actions: {
          [ACTION_COPY_ID]: {
            text: `Copy group ID: ${defaultProps.group.id}`,
            action: expect.any(Function),
          },
          [ACTION_EDIT]: {
            href: group.editPath,
          },
          [ACTION_ARCHIVE]: {
            action: expect.any(Function),
          },
          [ACTION_UNARCHIVE]: {
            action: expect.any(Function),
          },
          [ACTION_RESTORE]: {
            action: expect.any(Function),
          },
          [ACTION_DELETE]: {
            action: expect.any(Function),
          },
          [ACTION_LEAVE]: {
            action: expect.any(Function),
          },
        },
        availableActions: [ACTION_COPY_ID, ACTION_EDIT, ACTION_LEAVE, ACTION_DELETE],
      });
    });
  });

  describe('when copy ID action is fired', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('tracks event', async () => {
      copyToClipboard.mockResolvedValueOnce();
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      await fireAction(ACTION_COPY_ID);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_copy_id_in_group_quick_actions',
        {},
        undefined,
      );
    });

    describe('when copy to clipboard is successful', () => {
      it('shows toast', async () => {
        copyToClipboard.mockResolvedValueOnce();
        createComponent();
        await fireAction(ACTION_COPY_ID);
        await waitForPromises();

        expect(copyToClipboard).toHaveBeenCalledWith(defaultProps.group.id);
        expect(mockToast.show).toHaveBeenCalledWith('Group ID copied to clipboard.');
      });
    });

    describe('when copy to clipboard is not successful', () => {
      it('logs error in Sentry', async () => {
        const error = new Error('Copy command failed');
        copyToClipboard.mockRejectedValueOnce(error);
        createComponent();
        await fireAction(ACTION_COPY_ID);
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });
    });
  });

  describe('when archive action is fired', () => {
    beforeEach(() => {
      createComponent();
    });

    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('should call trackEvent method', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await fireAction(ACTION_ARCHIVE);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'archive_namespace_in_quick_action',
        {
          label: RESOURCE_TYPES.GROUP,
          property: 'archive',
        },
        undefined,
      );
    });

    describe('when API call is successful', () => {
      beforeEach(() => {
        createComponent();
      });

      it('calls archiveGroup, properly renders loading icon, and emits refetch event', async () => {
        archiveGroup.mockResolvedValueOnce();

        await fireAction(ACTION_ARCHIVE);

        expect(archiveGroup).toHaveBeenCalledWith(group.id);
        expect(findLoadingIcon().exists()).toBe(true);

        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(wrapper.emitted('refetch')).toEqual([[]]);
        expect(renderArchiveSuccessToast).toHaveBeenCalledWith(group);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      beforeEach(() => {
        createComponent();
      });

      const error = new Error();

      it('calls archiveGroup, properly sets loading state, and shows error alert', async () => {
        archiveGroup.mockRejectedValue(error);

        await fireAction(ACTION_ARCHIVE);

        expect(archiveGroup).toHaveBeenCalledWith(group.id);
        expect(findLoadingIcon().exists()).toBe(true);

        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(wrapper.emitted('refetch')).toBeUndefined();
        expect(renderArchiveSuccessToast).not.toHaveBeenCalledWith(group);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred archiving this group. Please refresh the page to try again.',
          error,
          captureError: true,
        });
      });
    });
  });

  describe('when unarchive action is fired', () => {
    beforeEach(() => {
      createComponent();
    });

    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('should call trackEvent method', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await fireAction(ACTION_UNARCHIVE);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'archive_namespace_in_quick_action',
        {
          label: RESOURCE_TYPES.GROUP,
          property: 'unarchive',
        },
        undefined,
      );
    });

    describe('when API call is successful', () => {
      it('calls unarchiveGroup, properly renders loading icon, and emits refetch event', async () => {
        unarchiveGroup.mockResolvedValueOnce();

        await fireAction(ACTION_UNARCHIVE);

        expect(unarchiveGroup).toHaveBeenCalledWith(group.id);
        expect(findLoadingIcon().exists()).toBe(true);

        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(wrapper.emitted('refetch')).toEqual([[]]);
        expect(renderUnarchiveSuccessToast).toHaveBeenCalledWith(group);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls unarchiveGroup, properly sets loading state, and shows error alert', async () => {
        unarchiveGroup.mockRejectedValue(error);

        await fireAction(ACTION_UNARCHIVE);

        expect(unarchiveGroup).toHaveBeenCalledWith(group.id);
        expect(findLoadingIcon().exists()).toBe(true);

        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(wrapper.emitted('refetch')).toBeUndefined();
        expect(renderUnarchiveSuccessToast).not.toHaveBeenCalledWith(group);
        expect(createAlert).toHaveBeenCalledWith({
          message:
            'An error occurred unarchiving this group. Please refresh the page to try again.',
          error,
          captureError: true,
        });
      });
    });
  });

  describe('when restore action is fired', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when API call is successful', () => {
      it('calls restoreGroup, properly renders loading icon, and emits refetch event', async () => {
        restoreGroup.mockResolvedValueOnce();

        await fireAction(ACTION_RESTORE);

        expect(restoreGroup).toHaveBeenCalledWith(group.id);
        expect(findLoadingIcon().exists()).toBe(true);

        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(wrapper.emitted('refetch')).toEqual([[]]);
        expect(renderRestoreSuccessToast).toHaveBeenCalledWith(group);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls restoreGroup, properly sets loading state, and shows error alert', async () => {
        restoreGroup.mockRejectedValue(error);

        await fireAction(ACTION_RESTORE);

        expect(restoreGroup).toHaveBeenCalledWith(group.id);
        expect(findLoadingIcon().exists()).toBe(true);

        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(wrapper.emitted('refetch')).toBeUndefined();
        expect(renderRestoreSuccessToast).not.toHaveBeenCalledWith(group);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred restoring this group. Please refresh the page to try again.',
          error,
          captureError: true,
        });
      });
    });
  });

  describe('when delete action is fired', () => {
    describe('when group is linked to a subscription', () => {
      const groupLinkedToSubscription = {
        ...group,
        isLinkedToSubscription: true,
      };

      beforeEach(async () => {
        createComponent({
          propsData: {
            group: groupLinkedToSubscription,
          },
        });
        await fireAction(ACTION_DELETE);
      });

      it('displays prevent delete modal', () => {
        expect(findPreventDeleteModal().props()).toMatchObject({
          visible: true,
        });
      });

      describe('when change is fired', () => {
        beforeEach(() => {
          findPreventDeleteModal().vm.$emit('change', false);
        });

        it('updates visibility prop', () => {
          expect(findPreventDeleteModal().props('visible')).toBe(false);
        });
      });
    });

    describe('when group can be deleted', () => {
      beforeEach(async () => {
        createComponent();

        await fireAction(ACTION_DELETE);
      });

      it('displays confirmation modal with correct props', () => {
        expect(findDeleteConfirmationModal().props()).toMatchObject({
          visible: true,
          phrase: group.fullName,
          confirmLoading: false,
        });
      });

      describe('when deletion is confirmed', () => {
        describe('when API call is successful', () => {
          it('calls DELETE on group path, properly sets loading state, and emits refetch event', async () => {
            axiosMock.onDelete(group.relativeWebUrl).reply(200);

            await deleteModalFireConfirmEvent();
            expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(true);

            await waitForPromises();

            expect(axiosMock.history.delete[0].params).toEqual(MOCK_DELETE_PARAMS);
            expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(false);
            expect(wrapper.emitted('refetch')).toEqual([[]]);
            expect(renderDeleteSuccessToast).toHaveBeenCalledWith(group);
            expect(createAlert).not.toHaveBeenCalled();
          });
        });

        describe('when API call is not successful', () => {
          it('calls DELETE on group path, properly sets loading state, and shows error alert', async () => {
            axiosMock.onDelete(group.relativeWebUrl).networkError();

            await deleteModalFireConfirmEvent();
            expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(true);

            await waitForPromises();

            expect(axiosMock.history.delete[0].params).toEqual(MOCK_DELETE_PARAMS);
            expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(false);
            expect(wrapper.emitted('refetch')).toBeUndefined();
            expect(createAlert).toHaveBeenCalledWith({
              message:
                'An error occurred deleting the group. Please refresh the page to try again.',
              error: new Error('Network Error'),
              captureError: true,
            });
            expect(renderDeleteSuccessToast).not.toHaveBeenCalled();
          });
        });
      });

      describe('when change is fired', () => {
        beforeEach(() => {
          findDeleteConfirmationModal().vm.$emit('change', false);
        });

        it('updates visibility prop', () => {
          expect(findDeleteConfirmationModal().props('visible')).toBe(false);
        });
      });
    });
  });

  describe('when delete immediately action is fired', () => {
    beforeEach(async () => {
      createComponent();
      await fireAction(ACTION_DELETE_IMMEDIATELY);
    });

    it('displays confirmation modal with correct props', () => {
      expect(findDeleteConfirmationModal().props()).toMatchObject({
        visible: true,
        phrase: group.fullName,
        confirmLoading: false,
      });
    });
  });

  describe('when leave action is fired', () => {
    beforeEach(async () => {
      createComponent();
      await fireAction(ACTION_LEAVE);
    });

    it('shows leave modal', () => {
      expect(findLeaveModal().props('visible')).toBe(true);
    });

    describe('when leave modal emits visibility change', () => {
      it("updates the modal's visibility prop", async () => {
        findLeaveModal().vm.$emit('change', false);

        await nextTick();

        expect(findLeaveModal().props('visible')).toBe(false);
      });
    });

    describe('when leave modal emits success event', () => {
      it('emits refetch event', () => {
        findLeaveModal().vm.$emit('success');

        expect(wrapper.emitted('refetch')).toEqual([[]]);
      });
    });
  });

  describe('when group does not have requestAccessPath', () => {
    it('does not display Request access action', () => {
      createComponent();

      expect(findListActions().props('actions')[ACTION_REQUEST_ACCESS]).toBeUndefined();
    });
  });

  describe('when group has requestAccessPath', () => {
    it('displays Request access action', () => {
      const requestAccessPath = '/request_access';

      createComponent({
        propsData: { group: { ...group, requestAccessPath } },
      });

      expect(findListActions().props('actions')[ACTION_REQUEST_ACCESS]).toEqual({
        href: requestAccessPath,
        extraAttrs: {
          'data-method': 'post',
          'data-testid': 'request-access-link',
          rel: 'nofollow',
        },
      });
    });
  });

  describe('when group does not have withdrawAccessRequestPath', () => {
    it('does not display Withdraw access request action', () => {
      createComponent();

      expect(findListActions().props('actions')[ACTION_WITHDRAW_ACCESS_REQUEST]).toBeUndefined();
    });
  });

  describe('when group has withdrawAccessRequestPath', () => {
    it('displays Withdraw access request action', () => {
      const withdrawAccessRequestPath = '/withdraw_access_request';

      createComponent({
        propsData: { group: { ...group, withdrawAccessRequestPath } },
      });

      expect(findListActions().props('actions')[ACTION_WITHDRAW_ACCESS_REQUEST]).toEqual({
        href: withdrawAccessRequestPath,
        extraAttrs: {
          'data-method': 'delete',
          'data-testid': 'withdraw-access-link',
          'data-confirm': `Are you sure you want to withdraw your access request for the ${group.fullName} group?`,
          rel: 'nofollow',
        },
      });
    });
  });
});
