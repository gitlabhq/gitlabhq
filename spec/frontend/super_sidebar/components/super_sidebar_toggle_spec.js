import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { JS_TOGGLE_EXPAND_CLASS } from '~/super_sidebar/constants';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { toggleSuperSidebarCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager.js', () => ({
  toggleSuperSidebarCollapsed: jest.fn(),
}));

describe('SuperSidebarToggle component', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  const createWrapper = () => {
    wrapper = shallowMountExtended(SuperSidebarToggle);
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('attributes', () => {
    it('has aria-controls attribute', () => {
      expect(findButton().attributes('aria-controls')).toBe('super-sidebar');
    });

    it('has aria-expanded as false', () => {
      expect(findButton().attributes('aria-expanded')).toBe('false');
    });

    it('has aria-label attribute', () => {
      expect(findButton().attributes('aria-label')).toBe('Open navigation menu');
    });

    it('has the class the sidebar Esc handler returns focus to', () => {
      expect(findButton().classes()).toContain(JS_TOGGLE_EXPAND_CLASS);
    });

    it('uses the hamburger icon', () => {
      expect(findButton().props('icon')).toBe('hamburger');
    });
  });

  describe('when clicked', () => {
    it('opens the sidebar', () => {
      findButton().vm.$emit('click');

      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledWith(false);
    });
  });
});
