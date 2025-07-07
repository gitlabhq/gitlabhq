import { GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import {
  ACTION_EDIT,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_RESTORE,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import { groups } from 'jest/vue_shared/components/groups_list/mock_data';
import { restoreGroup } from '~/api/groups_api';
import waitForPromises from 'helpers/wait_for_promises';
import { renderRestoreSuccessToast } from '~/vue_shared/components/groups_list/utils';
import { createAlert } from '~/alert';
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';

jest.mock('~/vue_shared/components/groups_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/groups_list/utils'),
  renderRestoreSuccessToast: jest.fn(),
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
        availableActions: [ACTION_EDIT, ACTION_DELETE, ACTION_RESTORE, ACTION_LEAVE],
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
