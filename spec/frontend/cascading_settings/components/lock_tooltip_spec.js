import { GlLink, GlTooltip, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LockTooltip from '~/namespaces/cascading_settings/components/lock_tooltip.vue';

describe('LockTooltip', () => {
  const mockNamespace = {
    fullName: 'GitLab Org / GitLab',
    path: '/gitlab-org/gitlab/-/edit',
  };

  const applicationSettingMessage =
    'An administrator selected this setting for the instance and you cannot change it.';

  let wrapper;
  const tooltipMountEl = document.createElement('div');

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(LockTooltip, {
      propsData: {
        ancestorNamespace: mockNamespace,
        isLockedByAdmin: false,
        isLockedByGroupAncestor: false,
        targetElement: tooltipMountEl,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  describe('when setting is locked by an admin setting', () => {
    beforeEach(() => {
      createWrapper({ isLockedByAdmin: true });
    });

    it('displays correct tooltip message', () => {
      expect(findTooltip().text()).toBe(applicationSettingMessage);
    });

    it('sets `target` prop correctly', () => {
      expect(findTooltip().props().target).toBe(tooltipMountEl);
    });
  });

  describe('when setting is locked by an ancestor namespace', () => {
    describe('and ancestorNamespace is set', () => {
      beforeEach(() => {
        createWrapper({
          isLockedByGroupAncestor: true,
          ancestorNamespace: mockNamespace,
        });
      });

      it('displays correct tooltip message', () => {
        expect(findTooltip().text()).toBe(
          `This setting has been enforced by an owner of ${mockNamespace.fullName}.`,
        );
      });

      it('displays link to ancestor namespace', () => {
        expect(findLink().attributes().href).toBe(mockNamespace.path);
      });

      it('sets `target` prop correctly', () => {
        expect(findTooltip().props().target).toBe(tooltipMountEl);
      });
    });

    describe('and ancestorNamespace is not set', () => {
      beforeEach(() => {
        createWrapper({ isLockedByGroupAncestor: true, ancestorNamespace: null });
      });

      it('displays a generic message', () => {
        expect(findTooltip().text()).toBe(
          `This setting has been enforced by an owner and cannot be changed.`,
        );
      });
    });
  });

  describe('when setting is locked by an application setting and an ancestor namespace', () => {
    beforeEach(() => {
      createWrapper({
        isLockedByAdmin: true,
        isLockedByGroupAncestor: true,
      });
    });

    it('displays correct tooltip message', () => {
      expect(findTooltip().text()).toBe(applicationSettingMessage);
    });

    it('sets `target` prop correctly', () => {
      expect(findTooltip().props().target).toBe(tooltipMountEl);
    });
  });

  describe('when setting is not locked', () => {
    beforeEach(() => {
      createWrapper({ isLockedByAdmin: false, isLockedByGroupAncestor: false });
    });

    it('does not render tooltip', () => {
      expect(findTooltip().exists()).toBe(false);
    });
  });
});
