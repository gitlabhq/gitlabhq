import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as touchDetection from '~/lib/utils/touch_detection';
import { JS_TOGGLE_COLLAPSE_CLASS, JS_TOGGLE_EXPAND_CLASS } from '~/super_sidebar/constants';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { toggleSuperSidebarCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager.js', () => ({
  toggleSuperSidebarCollapsed: jest.fn(),
}));

describe('SuperSidebarToggle component', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip').value;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(SuperSidebarToggle, {
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

    it('has aria-expanded as true when type is collapse', () => {
      createWrapper({ type: 'collapse' });
      expect(findButton().attributes('aria-expanded')).toBe('true');
    });

    it('has aria-expanded as false when type is expand', () => {
      createWrapper();
      expect(findButton().attributes('aria-expanded')).toBe('false');
    });

    it('has aria-label attribute', () => {
      createWrapper();
      expect(findButton().attributes('aria-label')).toBe('Primary navigation sidebar');
    });
  });

  describe('tooltip behavior', () => {
    beforeEach(() => {
      jest.spyOn(touchDetection, 'hasTouchCapability');
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    describe('on non-touch devices', () => {
      beforeEach(() => {
        touchDetection.hasTouchCapability.mockReturnValue(false);
      });

      it('displays "Hide sidebar" when type is collapse', () => {
        createWrapper({ type: 'collapse' });
        expect(getTooltip().title).toBe('Hide sidebar');
        expect(getTooltip().placement).toBe('bottom');
        expect(getTooltip().container).toBe('super-sidebar');
      });

      it('displays "Keep sidebar visible" when type is expand', () => {
        createWrapper();
        expect(getTooltip().title).toBe('Keep sidebar visible');
        expect(getTooltip().placement).toBe('right');
      });
    });

    describe('on touch devices', () => {
      beforeEach(() => {
        touchDetection.hasTouchCapability.mockReturnValue(true);
      });

      it('disables tooltip when type is expand', () => {
        createWrapper({ type: 'expand' });

        expect(getTooltip()).toBeNull();
      });

      it('disables tooltip when type is collapse', () => {
        createWrapper({ type: 'collapse' });

        expect(getTooltip()).toBeNull();
      });

      it('calls hasTouchCapability when computing tooltip', () => {
        createWrapper();

        expect(touchDetection.hasTouchCapability).toHaveBeenCalled();
      });
    });
  });

  describe('toggle', () => {
    let trackingSpy = null;

    beforeEach(() => {
      setHTMLFixture(`
        <button class="${JS_TOGGLE_COLLAPSE_CLASS}">Hide</button>
        <button class="${JS_TOGGLE_EXPAND_CLASS}">Show</button>
      `);
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      resetHTMLFixture();
      unmockTracking();
    });

    it('collapses the sidebar and focuses the expand toggle', async () => {
      createWrapper({ type: 'collapse' });
      findButton().vm.$emit('click');
      await nextTick();
      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledWith(true);
      expect(document.activeElement).toEqual(document.querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`));
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'nav_hide', {
        label: 'nav_toggle',
        property: 'nav_sidebar',
      });
    });

    it('expands the sidebar and focuses the collapse toggle', async () => {
      createWrapper({ type: 'expand' });
      findButton().vm.$emit('click');
      await nextTick();
      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledWith(false);
      expect(document.activeElement).toEqual(
        document.querySelector(`.${JS_TOGGLE_COLLAPSE_CLASS}`),
      );
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'nav_show', {
        label: 'nav_toggle',
        property: 'nav_sidebar',
      });
    });
  });

  describe('icon', () => {
    it('uses "sidebar" as default', () => {
      createWrapper();
      expect(findButton().props('icon')).toBe('sidebar');
    });

    it('uses icon from prop if given', () => {
      createWrapper({ icon: 'hamburger' });
      expect(findButton().props('icon')).toBe('hamburger');
    });
  });
});
