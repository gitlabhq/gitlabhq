import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoleUpdater from '~/members/components/table/drawer/role_updater.vue';
import { callRoleUpdateApi, setMemberRole } from '~/members/components/table/drawer/utils';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { member } from '../../../mock_data';

jest.mock('~/members/components/table/drawer/utils');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('Role updater CE', () => {
  let wrapper;
  const role = {};

  const createWrapper = ({ slotContent = '' } = {}) => {
    wrapper = shallowMountExtended(RoleUpdater, {
      propsData: { member, role },
      scopedSlots: { default: slotContent },
    });
  };

  it('renders slot content', () => {
    const slotContent = '<span>slot content</span>';
    createWrapper({ slotContent });

    expect(wrapper.html()).toContain(slotContent);
  });

  describe('when save is started', () => {
    beforeEach(() => {
      createWrapper();
      // NOTE: We can't call wrapper.vm.saveRole() here because the tests will run on the next tick, so the microtask
      // queue will be flushed beforehand and the entire saveRole function finishes executing. We need to instead call
      // saveRole on the same frame as the expect() checks so that the microtask queue doesn't get a chance to flush.
    });

    it('emits busy = true event', () => {
      wrapper.vm.saveRole();

      expect(wrapper.emitted('busy')).toHaveLength(1);
      expect(wrapper.emitted('busy')[0][0]).toBe(true);
    });

    it('calls role update API', () => {
      wrapper.vm.saveRole();

      expect(callRoleUpdateApi).toHaveBeenCalledTimes(1);
      expect(callRoleUpdateApi).toHaveBeenCalledWith(member, role);
    });

    it('does not update member', () => {
      wrapper.vm.saveRole();

      expect(setMemberRole).not.toHaveBeenCalled();
    });

    it('emits alert event to clear alert', () => {
      wrapper.vm.saveRole();

      expect(wrapper.emitted('alert')).toHaveLength(1);
      expect(wrapper.emitted('alert')[0][0]).toBe(null);
    });

    it('does not emit busy = false event', () => {
      wrapper.vm.saveRole();

      expect(wrapper.emitted('busy')).not.toHaveLength(2);
    });
  });

  describe('when save is successful', () => {
    beforeEach(() => {
      createWrapper();
      wrapper.vm.saveRole();

      return nextTick();
    });

    it('updates member role', () => {
      expect(setMemberRole).toHaveBeenCalledTimes(1);
      expect(setMemberRole).toHaveBeenCalledWith(member, role);
    });

    it('emits success alert', () => {
      expect(wrapper.emitted('alert')).toHaveLength(2);
      expect(wrapper.emitted('alert')[1][0]).toEqual({
        message: 'Role was successfully updated.',
        variant: 'success',
      });
    });

    it('emits busy = false event', () => {
      expect(wrapper.emitted('busy')).toHaveLength(2);
      expect(wrapper.emitted('busy')[1][0]).toBe(false);
    });
  });

  describe('when save has an error', () => {
    const error = new Error();

    beforeEach(() => {
      callRoleUpdateApi.mockRejectedValue(error);
      createWrapper();
      wrapper.vm.saveRole();
    });

    it('emits error alert', () => {
      expect(wrapper.emitted('alert')).toHaveLength(2);
      expect(wrapper.emitted('alert')[1][0]).toEqual({
        message: 'Could not update role.',
        variant: 'danger',
        dismissible: false,
      });
    });

    it('captures sentry exception', () => {
      expect(captureException).toHaveBeenCalledTimes(1);
      expect(captureException).toHaveBeenCalledWith(error);
    });

    it('emits busy = false event', () => {
      expect(wrapper.emitted('busy')).toHaveLength(2);
      expect(wrapper.emitted('busy')[1][0]).toBe(false);
    });
  });

  describe('when save has an error with a message', () => {
    const error = new Error();
    const message =
      "The member's email address is not allowed for this group. Check with your administrator.";
    error.response = {
      data: { message },
    };

    beforeEach(() => {
      callRoleUpdateApi.mockRejectedValue(error);
      createWrapper();
      wrapper.vm.saveRole();
    });

    it('emits error alert with that message', () => {
      expect(wrapper.emitted('alert')).toHaveLength(2);
      expect(wrapper.emitted('alert')[1][0]).toEqual({
        message,
        variant: 'danger',
        dismissible: false,
      });
    });
  });
});
