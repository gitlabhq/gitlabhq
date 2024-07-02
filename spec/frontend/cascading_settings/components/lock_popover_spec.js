import { GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LockPopover from '~/namespaces/cascading_settings/components/lock_popover.vue';

describe('LockPopover', () => {
  const mockNamespace = {
    fullName: 'GitLab Org / GitLab',
    path: '/gitlab-org/gitlab/-/edit',
  };

  const applicationSettingMessage =
    'An administrator selected this setting for the instance and you cannot change it.';

  let wrapper;
  const popoverMountEl = document.createElement('div');

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(LockPopover, {
      propsData: {
        ancestorNamespace: mockNamespace,
        isLockedByAdmin: false,
        isLockedByGroupAncestor: true,
        targetElement: popoverMountEl,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findPopover = () => wrapper.findComponent(GlPopover);

  describe('when setting is locked by an admin setting', () => {
    beforeEach(() => {
      createWrapper({ isLockedByAdmin: true });
    });

    it('displays correct popover message', () => {
      expect(findPopover().text()).toBe(applicationSettingMessage);
    });

    it('sets `target` prop correctly', () => {
      expect(findPopover().props().target).toBe(popoverMountEl);
    });
  });

  describe('when setting is locked by an ancestor namespace', () => {
    describe('and ancestorNamespace is set', () => {
      beforeEach(() => {
        createWrapper({ isLockedByGroupAncestor: true, ancestorNamespace: mockNamespace });
      });

      it('displays correct popover message', () => {
        expect(findPopover().text()).toBe(
          `This setting has been enforced by an owner of ${mockNamespace.fullName}.`,
        );
      });

      it('displays link to ancestor namespace', () => {
        expect(findLink().attributes().href).toBe(mockNamespace.path);
      });

      it('sets `target` prop correctly', () => {
        expect(findPopover().props().target).toBe(popoverMountEl);
      });
    });

    describe('and ancestorNamespace is not set', () => {
      beforeEach(() => {
        createWrapper({ isLockedByGroupAncestor: true, ancestorNamespace: null });
      });

      it('displays a generic message', () => {
        expect(findPopover().text()).toBe(
          `This setting has been enforced by an owner and cannot be changed.`,
        );
      });
    });
  });

  describe('when setting is locked by an application setting and an ancestor namespace', () => {
    beforeEach(() => {
      createWrapper({ isLockedByAdmin: true, isLockedByGroupAncestor: true });
    });

    it('displays correct popover message', () => {
      expect(findPopover().text()).toBe(applicationSettingMessage);
    });

    it('sets `target` prop correctly', () => {
      expect(findPopover().props().target).toBe(popoverMountEl);
    });
  });

  describe('when setting is not locked', () => {
    beforeEach(() => {
      createWrapper({ isLockedByAdmin: false, isLockedByGroupAncestor: false });
    });

    it('does not render popover', () => {
      expect(findPopover().exists()).toBe(false);
    });
  });
});
