import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import PanelWidthResizer from '~/vue_shared/components/panel_width_resizer.vue';
import AccessiblePanelResizer from '~/vue_shared/components/accessible_panel_resizer.vue';

describe('PanelWidthResizer', () => {
  let wrapper;
  let targetEl;

  const findResizer = () => wrapper.findComponent(AccessiblePanelResizer);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PanelWidthResizer, {
      propsData: {
        targetEl,
        ...props,
      },
    });
  };

  let containerEl;
  let siblingEl;

  const setContainerWidth = (width) => {
    jest.spyOn(containerEl, 'getBoundingClientRect').mockReturnValue({ width });
  };

  const createSibling = (offsetWidth) => {
    const el = document.createElement('div');
    Object.defineProperty(el, 'offsetWidth', { value: offsetWidth });
    containerEl.appendChild(el);
    return el;
  };

  beforeEach(() => {
    jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(true);
    containerEl = document.createElement('div');
    targetEl = document.createElement('div');
    containerEl.appendChild(targetEl);
    // A visible sibling panel shares the row; without one there is nothing
    // to resize against and the handle hides.
    siblingEl = createSibling(500);
    document.body.appendChild(containerEl);
  });

  afterEach(() => {
    containerEl.remove();
    containerEl = null;
    targetEl = null;
    siblingEl = null;
  });

  it('renders the resizer and passes the side through', () => {
    createComponent({ side: 'right' });

    expect(findResizer().exists()).toBe(true);
    expect(findResizer().props('side')).toBe('right');
  });

  it('labels the handle with the given panel name and names the landmark from it', () => {
    createComponent({ resizeLabel: 'Resize static panel' });

    expect(findResizer().props('ariaLabel')).toBe('Resize static panel');
    expect(wrapper.find('section').attributes('aria-label')).toBeUndefined();
    expect(wrapper.find('section').attributes('aria-labelledby')).toBe(
      findResizer().attributes('id'),
    );
  });

  describe('sibling visibility', () => {
    it('hides the resizer when the panel is alone in its container', () => {
      siblingEl.remove();
      createComponent();

      expect(findResizer().exists()).toBe(false);
    });

    it('hides the resizer when all sibling panels are hidden', () => {
      siblingEl.remove();
      createSibling(0);
      createComponent();

      expect(findResizer().exists()).toBe(false);
    });
  });

  it('does not render the resizer below the desktop breakpoint', () => {
    PanelBreakpointInstance.isDesktop.mockReturnValue(false);
    createComponent();

    expect(findResizer().exists()).toBe(false);
  });

  it('applies the dragged width and pins the flex basis on the target element', async () => {
    createComponent();

    await findResizer().vm.$emit('input', 640);

    expect(targetEl.style.width).toBe('640px');
    expect(targetEl.style.flex).toBe('0 0 auto');
  });

  it('clears the inline styles when the resizer resets', async () => {
    createComponent();

    await findResizer().vm.$emit('input', 640);
    await findResizer().vm.$emit('input', null);

    expect(targetEl.style.width).toBe('');
    expect(targetEl.style.flex).toBe('');
  });

  it('restores a previously applied target width on remount', async () => {
    setContainerWidth(1600);
    targetEl.style.width = '640px';
    createComponent();
    await nextTick();

    expect(findResizer().props('value')).toBe(640);
  });

  describe('maximum width', () => {
    it('derives the maximum from the panels container, not the viewport', async () => {
      setContainerWidth(1000);
      createComponent();
      await nextTick();

      // container - MIN_PANEL_PX: the sibling panel keeps its minimum
      expect(findResizer().props('maxSize')).toBe(600);
    });

    it('does not reserve the sibling minimum for an overlay panel', async () => {
      // The stacked (absolute) overlay covers its sibling; its cap must
      // match the painted CSS default so a drag starts without a jump
      setContainerWidth(1000);
      targetEl.style.position = 'absolute';
      createComponent();
      await nextTick();

      expect(findResizer().props('maxSize')).toBe(800);
    });

    it('reserves the sibling panel minimum before applying the fraction cap', async () => {
      setContainerWidth(1600);
      createComponent();
      await nextTick();

      // min(0.8 * 1600, 1600 - 400)
      expect(findResizer().props('maxSize')).toBe(1200);
    });

    it('clamps a restored width that exceeds the container-based maximum', async () => {
      setContainerWidth(1000);
      targetEl.style.width = '2000px';
      createComponent();
      await nextTick();

      expect(findResizer().props('value')).toBe(600);
      expect(targetEl.style.width).toBe('600px');
    });

    it('does not restore a stored width into a container that cannot honor any', async () => {
      setContainerWidth(450);
      targetEl.style.width = '900px';
      createComponent();
      await nextTick();

      expect(findResizer().props('value')).toBe(null);
      expect(targetEl.style.width).toBe('');
    });

    it('drops the pinned width entirely when the container cannot honor any', async () => {
      setContainerWidth(2000);
      createComponent();
      await findResizer().vm.$emit('input', 1200);

      // 450 * 0.8 < MIN_PANEL_PX: no pixel width fits, fall back to CSS
      setContainerWidth(450);
      window.dispatchEvent(new Event('resize'));
      await nextTick();

      expect(findResizer().props('value')).toBe(null);
      expect(targetEl.style.width).toBe('');
      expect(targetEl.style.flex).toBe('');
    });

    it('re-clamps the dragged width when the container shrinks', async () => {
      setContainerWidth(2000);
      createComponent();
      await findResizer().vm.$emit('input', 1200);

      setContainerWidth(1000);
      window.dispatchEvent(new Event('resize'));
      await nextTick();

      expect(findResizer().props('value')).toBe(600);
      expect(targetEl.style.width).toBe('600px');
    });
  });

  describe('hideWhenVisibleEl', () => {
    let overlapEl;

    afterEach(() => {
      overlapEl.remove();
      overlapEl = null;
    });

    const createWithOverlapEl = (offsetWidth) => {
      overlapEl = document.createElement('div');
      Object.defineProperty(overlapEl, 'offsetWidth', { value: offsetWidth });
      document.body.appendChild(overlapEl);

      createComponent({ hideWhenVisibleEl: overlapEl });
    };

    it('hides the resizer while the element is visible', async () => {
      createWithOverlapEl(500);
      await nextTick();

      expect(findResizer().exists()).toBe(false);
    });

    it('shows the resizer while the element is hidden', async () => {
      createWithOverlapEl(0);
      await nextTick();

      expect(findResizer().exists()).toBe(true);
    });
  });
});
