import { mountExtended } from 'helpers/vue_test_utils_helper';
import AccessiblePanelResizer, {
  DEFAULT_STEP_PX,
  DEFAULT_LARGE_STEP_PX,
} from '~/vue_shared/components/accessible_panel_resizer.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';

describe('AccessiblePanelResizer', () => {
  let wrapper;

  const DEFAULT_PROPS = {
    defaultSize: 500,
    minSize: 400,
    maxSize: 960,
    ariaLabel: 'Resize panel',
  };

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(AccessiblePanelResizer, {
      propsData: { ...DEFAULT_PROPS, ...propsData },
    });
  };

  const findPanelResizer = () => wrapper.findComponent(PanelResizer);
  // Keydown is bound via .native on the PanelResizer component; trigger on its root element.
  const triggerKey = (key, options = {}) =>
    findPanelResizer().trigger('keydown', { key, ...options });
  const lastInput = () => wrapper.emitted('input').at(-1)[0];

  beforeEach(() => {
    document.documentElement.removeAttribute('dir');
  });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('ARIA attributes', () => {
    it('forwards the required accessibility attributes onto the underlying handle', () => {
      createComponent();
      const el = findPanelResizer().element;
      expect(el.getAttribute('role')).toBe('separator');
      expect(el.getAttribute('aria-orientation')).toBe('vertical');
      expect(el.getAttribute('aria-label')).toBe('Resize panel');
      expect(el.getAttribute('tabindex')).toBe('0');
    });

    it('reports defaultSize as aria-valuenow when value is null', () => {
      createComponent({ value: null });
      expect(findPanelResizer().element.getAttribute('aria-valuenow')).toBe('500');
    });

    it('reports the controlled value as aria-valuenow when value is set', () => {
      createComponent({ value: 720 });
      expect(findPanelResizer().element.getAttribute('aria-valuenow')).toBe('720');
    });

    it('reflects minSize and maxSize on aria-valuemin / aria-valuemax', () => {
      createComponent({ minSize: 400, maxSize: 900 });
      const el = findPanelResizer().element;
      expect(el.getAttribute('aria-valuemin')).toBe('400');
      expect(el.getAttribute('aria-valuemax')).toBe('900');
    });

    it('clamps aria-valuenow to maxSize when the stored value exceeds the current ceiling', () => {
      // Reproduces: user dragged to 800 on a wide viewport, maximized,
      // shrank the window (so maxSize is now 600), then un-maximized.
      // CSS clamp would mask the visual symptom; the ARIA contract requires
      // aria-valuenow ∈ [aria-valuemin, aria-valuemax] regardless.
      createComponent({ value: 800, maxSize: 600 });
      expect(findPanelResizer().element.getAttribute('aria-valuenow')).toBe('600');
    });

    it('clamps aria-valuenow to minSize when the stored value is below the floor', () => {
      createComponent({ value: 200, minSize: 400 });
      expect(findPanelResizer().element.getAttribute('aria-valuenow')).toBe('400');
    });

    it('passes a clamped start-size to PanelResizer even when value exceeds maxSize', () => {
      createComponent({ value: 800, maxSize: 600 });
      // PanelResizer's start-size also derives from currentSize, so the next
      // drag begins from the visible width, not the stale stored preference.
      expect(findPanelResizer().props('startSize')).toBe(600);
    });
  });

  describe('keyboard navigation — LTR', () => {
    const START = 500;

    beforeEach(() => {
      createComponent({ value: START });
    });

    it('ArrowLeft widens the panel by DEFAULT_STEP_PX (currentSize + step)', async () => {
      await triggerKey('ArrowLeft');
      expect(lastInput()).toBe(START + DEFAULT_STEP_PX);
    });

    it('ArrowRight narrows the panel by DEFAULT_STEP_PX (currentSize - step)', async () => {
      await triggerKey('ArrowRight');
      expect(lastInput()).toBe(START - DEFAULT_STEP_PX);
    });

    it('Shift+ArrowLeft uses DEFAULT_LARGE_STEP_PX (4x normal step)', async () => {
      await triggerKey('ArrowLeft', { shiftKey: true });
      expect(lastInput()).toBe(START + DEFAULT_LARGE_STEP_PX);
    });

    it('Shift+ArrowRight uses DEFAULT_LARGE_STEP_PX', async () => {
      await triggerKey('ArrowRight', { shiftKey: true });
      expect(lastInput()).toBe(START - DEFAULT_LARGE_STEP_PX);
    });

    it('clamps to minSize when keypress would shrink below floor', async () => {
      createComponent({ value: 410 });
      await triggerKey('ArrowRight'); // 410 - 24 = 386, clamp to 400
      expect(lastInput()).toBe(400);
    });

    it('clamps to maxSize when keypress would exceed ceiling', async () => {
      createComponent({ value: 950 });
      await triggerKey('ArrowLeft'); // 950 + 24 = 974, clamp to 960
      expect(lastInput()).toBe(960);
    });

    it('End emits input = maxSize', async () => {
      await triggerKey('End');
      expect(lastInput()).toBe(960);
    });

    it('Home emits reset and input(null)', async () => {
      await triggerKey('Home');
      expect(wrapper.emitted('reset')).toHaveLength(1);
      expect(lastInput()).toBeNull();
    });

    it('ignores keys it does not handle', async () => {
      await triggerKey('Enter');
      await triggerKey('Tab');
      expect(wrapper.emitted('input')).toBeUndefined();
    });
  });

  describe('keyboard navigation — RTL', () => {
    const START = 500;

    beforeEach(() => {
      document.documentElement.setAttribute('dir', 'rtl');
      createComponent({ value: START });
    });

    it('ArrowLeft narrows in RTL (sign inverted from LTR widening)', async () => {
      await triggerKey('ArrowLeft');
      expect(lastInput()).toBe(START - DEFAULT_STEP_PX);
    });

    it('ArrowRight widens in RTL (sign inverted from LTR narrowing)', async () => {
      await triggerKey('ArrowRight');
      expect(lastInput()).toBe(START + DEFAULT_STEP_PX);
    });
  });

  describe('keyboard navigation — side="right" (handle on the panel right edge)', () => {
    const START = 500;

    beforeEach(() => {
      createComponent({ value: START, side: 'right' });
    });

    it('ArrowLeft narrows when handle is on the right edge (LTR)', async () => {
      await triggerKey('ArrowLeft');
      expect(lastInput()).toBe(START - DEFAULT_STEP_PX);
    });

    it('ArrowRight widens when handle is on the right edge (LTR)', async () => {
      await triggerKey('ArrowRight');
      expect(lastInput()).toBe(START + DEFAULT_STEP_PX);
    });
  });

  describe('keyboard navigation — RTL with side="right"', () => {
    const START = 500;

    beforeEach(() => {
      document.documentElement.setAttribute('dir', 'rtl');
      createComponent({ value: START, side: 'right' });
    });

    it('ArrowLeft widens with side="right" in RTL (both flips compose)', async () => {
      await triggerKey('ArrowLeft');
      expect(lastInput()).toBe(START + DEFAULT_STEP_PX);
    });

    it('ArrowRight narrows with side="right" in RTL', async () => {
      await triggerKey('ArrowRight');
      expect(lastInput()).toBe(START - DEFAULT_STEP_PX);
    });
  });

  describe('child PanelResizer wiring', () => {
    it('re-emits update:size from the child as input', () => {
      createComponent({ value: 500 });
      findPanelResizer().vm.$emit('update:size', 640);
      expect(lastInput()).toBe(640);
    });

    it('translates reset-size from the child into reset + input(null)', () => {
      createComponent({ value: 720 });
      findPanelResizer().vm.$emit('reset-size');
      expect(wrapper.emitted('reset')).toHaveLength(1);
      expect(lastInput()).toBeNull();
    });

    it('passes currentSize down as start-size', () => {
      createComponent({ value: 640 });
      expect(findPanelResizer().props('startSize')).toBe(640);
    });

    it('falls back to defaultSize for start-size when value is null', () => {
      createComponent({ value: null, defaultSize: 500 });
      expect(findPanelResizer().props('startSize')).toBe(500);
    });
  });

  describe('side resolution', () => {
    it('passes side through unchanged in LTR', () => {
      createComponent({ side: 'left' });
      expect(findPanelResizer().props('side')).toBe('left');
    });

    it('flips left to right in RTL', () => {
      document.documentElement.setAttribute('dir', 'rtl');
      createComponent({ side: 'left' });
      expect(findPanelResizer().props('side')).toBe('right');
    });

    it('flips right to left in RTL', () => {
      document.documentElement.setAttribute('dir', 'rtl');
      createComponent({ side: 'right' });
      expect(findPanelResizer().props('side')).toBe('left');
    });
  });

  describe('customClass', () => {
    it('merges consumer-supplied customClass with the wrapper defaults', () => {
      createComponent({ customClass: 'consumer-class' });
      const passed = findPanelResizer().props('customClass');
      expect(passed).toContain('gl-z-1');
      expect(passed).toContain('focus:gl-focus');
      expect(passed).toContain('consumer-class');
    });
  });
});
