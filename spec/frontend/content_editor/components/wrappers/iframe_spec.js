import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { iframeProviders, YOUTUBE_SANDBOX, FIGMA_SANDBOX } from 'helpers/iframe_providers';
import IframeWrapper from '~/content_editor/components/wrappers/iframe.vue';

describe('content/components/wrappers/iframe', () => {
  let wrapper;

  const mockEditor = {
    chain: jest.fn().mockReturnThis(),
    focus: jest.fn().mockReturnThis(),
    setNodeSelection: jest.fn().mockReturnThis(),
    run: jest.fn().mockReturnThis(),
  };

  beforeEach(() => {
    window.gon = {
      iframe_rendering_providers: iframeProviders(),
      features: { allowIframesInMarkdown: true },
    };
  });

  const createWrapper = (attrs = {}, { selected = false } = {}) => {
    wrapper = shallowMountExtended(IframeWrapper, {
      propsData: {
        node: { attrs: { providerId: 'youtube', ...attrs } },
        editor: mockEditor,
        getPos: () => 0,
        updateAttributes: jest.fn(),
        selected,
      },
    });
  };

  const findIframe = () => wrapper.find('iframe');
  const findOverlay = () => wrapper.findByTestId('iframe-overlay');

  it('renders an iframe with the correct src', () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    expect(findIframe().attributes('src')).toBe('https://www.youtube.com/embed/abc123');
  });

  it("applies the provider's sandbox restrictions", () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    expect(findIframe().attributes('sandbox')).toBe(YOUTUBE_SANDBOX);
  });

  it("applies the node's provider sandbox", () => {
    createWrapper({
      src: 'https://embed.figma.com/design/abc?embed-host=gitlab',
      providerId: 'figma',
    });

    expect(findIframe().attributes('sandbox')).toBe(FIGMA_SANDBOX);
  });

  it('sets referrerpolicy to strict-origin-when-cross-origin', () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    expect(findIframe().attributes('referrerpolicy')).toBe('strict-origin-when-cross-origin');
  });

  it('renders with explicit width and height', () => {
    createWrapper({
      src: 'https://www.youtube.com/embed/abc123',
      width: '560',
      height: '315',
    });

    const iframe = findIframe();
    expect(iframe.attributes('width')).toBe('560');
    expect(iframe.attributes('height')).toBe('315');
  });

  it('computes aspect-ratio style when both dimensions are explicit', () => {
    createWrapper({
      src: 'https://www.youtube.com/embed/abc123',
      width: '560',
      height: '315',
    });

    expect(wrapper.vm.iframeStyle).toEqual({
      aspectRatio: '560 / 315',
      height: 'auto',
      maxHeight: 'min(80vh, 315px)',
      maxWidth: '100%',
    });
  });

  it('sets a maximum height when dimensions are auto', () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    expect(wrapper.vm.iframeStyle).toEqual({ maxHeight: '80vh' });
  });

  it('applies full-width classes when no explicit dimensions are set', () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    const iframe = findIframe();
    expect(iframe.classes()).toContain('gl-inset-0');
    expect(iframe.classes()).toContain('gl-h-full');
    expect(iframe.classes()).toContain('gl-w-full');
  });

  it('does not apply full-width classes when explicit dimensions are set', () => {
    createWrapper({
      src: 'https://www.youtube.com/embed/abc123',
      width: '560',
      height: '315',
    });

    expect(findIframe().classes()).not.toContain('gl-inset-0');
  });

  describe('layout', () => {
    beforeEach(() => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123', width: '560', height: '315' });
    });

    it('lays the node out as a block, without stretching the embed', () => {
      expect(wrapper.classes()).toEqual(expect.arrayContaining(['gl-flex', 'gl-items-start']));
    });

    it('keeps the embed within its container, with a floor that yields to it', () => {
      const { style } = findIframe().element.parentElement;
      expect(style.maxWidth).toBe('100%');
      expect(style.minWidth).toBe('min(17rem, 100%)');
    });

    it('fills the embed with the iframe', () => {
      expect(findIframe().classes()).toContain('gl-min-w-full');
    });
  });

  describe('resizing', () => {
    const drag = (fromX, toX) => {
      wrapper.findByTestId('image-resize-se').trigger('mousedown', { screenX: fromX });
      document.dispatchEvent(new MouseEvent('mousemove', { screenX: toX }));
      document.dispatchEvent(new MouseEvent('mouseup'));
    };

    const setUpLayout = ({ rendered, available }) => {
      jest.spyOn(findIframe().element, 'getBoundingClientRect').mockReturnValue(rendered);
      Object.defineProperty(wrapper.element, 'clientWidth', { value: available });
    };

    const savedSize = () => wrapper.props('updateAttributes').mock.calls.at(-1)[0];

    beforeEach(() => {
      document.documentElement.style.fontSize = '16px';
    });

    afterEach(() => {
      document.documentElement.style.fontSize = '';
    });

    describe('when the requested size is below the floor', () => {
      beforeEach(() => {
        createWrapper(
          { src: 'https://www.youtube.com/embed/abc123', width: '10', height: '10' },
          { selected: true },
        );
        setUpLayout({ rendered: { width: 272, height: 10 }, available: 800 });
      });

      describe('when dragged wider', () => {
        beforeEach(() => {
          drag(200, 300);
        });

        it('resizes from the rendered size', () => {
          expect(savedSize()).toEqual({ width: 372, height: 13 });
        });
      });

      describe('when dragged narrower', () => {
        beforeEach(() => {
          drag(200, 100);
        });

        it('stops at the floor', () => {
          expect(savedSize()).toEqual({ width: 272, height: 10 });
        });
      });
    });

    describe('when the container is narrower than the floor', () => {
      beforeEach(() => {
        createWrapper(
          { src: 'https://www.youtube.com/embed/abc123', width: '560', height: '315' },
          { selected: true },
        );
        setUpLayout({ rendered: { width: 200, height: 112.5 }, available: 200 });
      });

      describe('when dragged narrower', () => {
        beforeEach(() => {
          drag(200, 100);
        });

        it('stops at the container width', () => {
          expect(savedSize()).toEqual({ width: 200, height: 113 });
        });
      });
    });
  });

  describe('overlay for click selection and drag', () => {
    it('renders an overlay that intercepts clicks when not selected', () => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123' }, { selected: false });

      const overlay = findOverlay();
      expect(overlay.exists()).toBe(true);
      expect(overlay.classes()).not.toContain('gl-pointer-events-none');
    });

    it('disables pointer events on the overlay after mouseup when selected', async () => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123' }, { selected: false });

      await wrapper.setProps({ selected: true });

      expect(findOverlay().classes()).not.toContain('gl-pointer-events-none');

      document.dispatchEvent(new MouseEvent('mouseup'));
      await nextTick();

      expect(findOverlay().classes()).toContain('gl-pointer-events-none');
    });

    it('restores pointer events when deselected', async () => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123' }, { selected: false });

      await wrapper.setProps({ selected: true });
      document.dispatchEvent(new MouseEvent('mouseup'));
      await nextTick();
      expect(findOverlay().classes()).toContain('gl-pointer-events-none');

      await wrapper.setProps({ selected: false });

      expect(findOverlay().classes()).not.toContain('gl-pointer-events-none');
    });

    it('has drag handle attributes for ProseMirror node dragging', () => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

      const overlay = findOverlay();
      expect(overlay.attributes('draggable')).toBe('true');
      expect(overlay.attributes('data-drag-handle')).toBe('');
    });

    it('sets a custom drag image and suppresses subsequent setDragImage calls', () => {
      createWrapper(
        { src: 'https://www.youtube.com/embed/abc123', width: '560', height: '315' },
        { selected: true },
      );

      const setDragImage = jest.fn();
      const event = new DragEvent('dragstart', { bubbles: true });
      Object.defineProperty(event, 'dataTransfer', {
        value: { setDragImage },
      });

      findOverlay().element.dispatchEvent(event);

      expect(setDragImage).toHaveBeenCalledTimes(1);
      expect(setDragImage).toHaveBeenCalledWith(expect.any(HTMLDivElement), 0, 0);

      const placeholder = setDragImage.mock.calls[0][0];
      expect(placeholder.className).toBe('iframe-drag-placeholder');

      event.dataTransfer.setDragImage(document.createElement('div'), 0, 0);
      expect(setDragImage).toHaveBeenCalledTimes(1);
    });
  });
});
