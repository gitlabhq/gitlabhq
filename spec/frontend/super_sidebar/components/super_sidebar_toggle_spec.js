import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { JS_TOGGLE_COLLAPSE_CLASS, JS_TOGGLE_EXPAND_CLASS } from '~/super_sidebar/constants';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { toggleSuperSidebarCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager.js', () => ({
  toggleSuperSidebarCollapsed: jest.fn(),
}));

describe('SuperSidebarToggle component', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip').value;

  const createWrapper = ({ props = {}, sidebarState = {} } = {}) => {
    wrapper = shallowMountExtended(SuperSidebarToggle, {
      data() {
        return {
          ...sidebarState,
        };
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...props,
      },
    });
  };

  describe('attributes', () => {
    it('has aria-controls attribute', () => {
      createWrapper();
      expect(findButton().attributes('aria-controls')).toBe('super-sidebar');
    });

    it('has aria-expanded as true when expanded', () => {
      createWrapper();
      expect(findButton().attributes('aria-expanded')).toBe('true');
    });

    it('has aria-expanded as false when collapsed', () => {
      createWrapper({ sidebarState: { isCollapsed: true } });
      expect(findButton().attributes('aria-expanded')).toBe('false');
    });

    it('has aria-label attribute', () => {
      createWrapper();
      expect(findButton().attributes('aria-label')).toBe(__('Navigation sidebar'));
    });

    it('is disabled when isPeek is true', () => {
      createWrapper({ sidebarState: { isPeek: true } });
      expect(findButton().attributes('disabled')).toBe('true');
    });
  });

  describe('toolip', () => {
    it('displays collapse when expanded', () => {
      createWrapper();
      expect(getTooltip().title).toBe(__('Hide sidebar'));
    });

    it('displays expand when collapsed', () => {
      createWrapper({ sidebarState: { isCollapsed: true } });
      expect(getTooltip().title).toBe(__('Show sidebar'));
    });
  });

  describe('toggle', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <button class="${JS_TOGGLE_COLLAPSE_CLASS}">Hide</button>
        <button class="${JS_TOGGLE_EXPAND_CLASS}">Show</button>
      `);
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('collapses the sidebar and focuses the other toggle', async () => {
      createWrapper();
      findButton().vm.$emit('click');
      await nextTick();
      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledWith(true, true);
      expect(document.activeElement).toEqual(
        document.querySelector(`.${JS_TOGGLE_COLLAPSE_CLASS}`),
      );
    });

    it('expands the sidebar and focuses the other toggle', async () => {
      createWrapper({ sidebarState: { isCollapsed: true } });
      findButton().vm.$emit('click');
      await nextTick();
      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledWith(false, true);
      expect(document.activeElement).toEqual(document.querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`));
    });
  });
});
