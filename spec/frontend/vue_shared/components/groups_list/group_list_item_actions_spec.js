import { GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
import GroupListItemDeleteModal from '~/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import GroupListItemLeaveModal from '~/vue_shared/components/groups_list/group_list_item_leave_modal.vue';
import {
  ACTION_ARCHIVE,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import { groups } from 'jest/vue_shared/components/groups_list/mock_data';
import { archiveGroup, restoreGroup, unarchiveGroup } from '~/api/groups_api';
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

describe('GroupListItemActions', () => {
  let wrapper;
  let axiosMock;

  const [group] = groups;
  const defaultProps = { group };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(GroupListItemActions, {
      propsData: { ...defaultProps, ...propsData },
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
        availableActions: [ACTION_EDIT, ACTION_LEAVE, ACTION_DELETE],
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
});
