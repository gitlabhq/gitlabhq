import { GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
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
} from '~/vue_shared/components/groups_list/utils';
import { createAlert } from '~/alert';
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

jest.mock('~/vue_shared/components/groups_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/groups_list/utils'),
  renderRestoreSuccessToast: jest.fn(),
  renderArchiveSuccessToast: jest.fn(),
  renderUnarchiveSuccessToast: jest.fn(),
}));
jest.mock('~/alert');
jest.mock('~/api/groups_api');

describe('GroupListItemActions', () => {
  let wrapper;

  const [group] = groups;
  const defaultProps = { group };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupListItemActions, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findListActions = () => wrapper.findComponent(ListActions);

  const fireAction = (action) => findListActions().props('actions')[action].action();

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
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
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('should call trackEvent method', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      fireAction(ACTION_ARCHIVE);
      await waitForPromises();

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
      it('calls archiveGroup, properly renders loading icon, and emits refetch event', async () => {
        archiveGroup.mockResolvedValueOnce();

        fireAction(ACTION_ARCHIVE);
        await nextTick();

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
      const error = new Error();

      it('calls archiveGroup, properly sets loading state, and shows error alert', async () => {
        archiveGroup.mockRejectedValue(error);

        fireAction(ACTION_ARCHIVE);
        await nextTick();

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
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('should call trackEvent method', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      fireAction(ACTION_UNARCHIVE);
      await waitForPromises();

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

        fireAction(ACTION_UNARCHIVE);
        await nextTick();

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

        fireAction(ACTION_UNARCHIVE);
        await nextTick();

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
    describe('when API call is successful', () => {
      it('calls restoreGroup, properly renders loading icon, and emits refetch event', async () => {
        restoreGroup.mockResolvedValueOnce();

        fireAction(ACTION_RESTORE);
        await nextTick();

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

        fireAction(ACTION_RESTORE);
        await nextTick();

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
    it('emits delete event', () => {
      fireAction(ACTION_DELETE);

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });

  describe('when delete immediately action is fired', () => {
    it('emits delete event', () => {
      fireAction(ACTION_DELETE_IMMEDIATELY);

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });

  describe('when leave action is fired', () => {
    it('emits leave event', () => {
      fireAction(ACTION_LEAVE);

      expect(wrapper.emitted('leave')).toEqual([[]]);
    });
  });
});
