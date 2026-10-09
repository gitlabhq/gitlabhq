import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { iframeProviders, YOUTUBE_SANDBOX, FIGMA_SANDBOX } from 'helpers/iframe_providers';
import ExternalContent from '~/behaviors/components/external_content.vue';
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
      stubs: { ExternalContent },
      attachTo: document.body,
    });
  };

  const findIframe = () => wrapper.find('iframe');
  const findOverlay = () => wrapper.findByTestId('iframe-overlay');
  const findEmbed = () => wrapper.findByTestId('iframe-embed');
  const findPlaceholder = () => wrapper.findByTestId('external-content-placeholder');
  const findResizeHandles = () => wrapper.findAll('.image-resize');
  const findExternalContent = () => wrapper.findComponent(ExternalContent);
  const findActivationButton = () => wrapper.findComponent(GlButton);
  const findOpenInNewTab = () => wrapper.findByTestId('external-content-open-in-new-tab');

  it('renders an iframe with the correct src', () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    expect(findIframe().attributes('src')).toBe('https://www.youtube.com/embed/abc123');
  });

  it("applies the provider's sandbox restrictions", () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    expect(findIframe().attributes('sandbox')).toBe(YOUTUBE_SANDBOX);
  });

  it('names the frame after the provider and host', () => {
    createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

    expect(findIframe().attributes('title')).toBe(
      'External content from YouTube (www.youtube.com)',
    );
  });

  it('wraps the iframe in the external content chrome', () => {
    createWrapper({
      src: 'https://www.youtube.com/embed/abc123',
      canonicalSrc: 'https://youtu.be/abc123',
      width: '560',
      height: '315',
    });

    expect(findExternalContent().props()).toMatchObject({
      provider: iframeProviders().youtube,
      href: 'https://youtu.be/abc123',
      width: '560',
      height: '315',
    });
  });

  it('links to the content in a new tab', () => {
    createWrapper({
      src: 'https://www.youtube.com/embed/abc123',
      canonicalSrc: 'https://youtu.be/abc123',
    });

    expect(findOpenInNewTab().attributes('href')).toBe('https://youtu.be/abc123');
  });

  describe('when the provider requires activation', () => {
    beforeEach(() => {
      createWrapper({
        src: 'https://embed.figma.com/design/abc?embed-host=gitlab',
        providerId: 'figma',
      });
    });

    it('does not render the iframe', () => {
      expect(findIframe().exists()).toBe(false);
    });

    it('does not render the selection overlay', () => {
      expect(findOverlay().exists()).toBe(false);
    });

    it('can still be dragged', () => {
      expect(findEmbed().attributes()).toMatchObject({ draggable: 'true', 'data-drag-handle': '' });
    });

    describe('when the user activates the content', () => {
      beforeEach(async () => {
        findActivationButton().vm.$emit('click');
        await waitForPromises();
      });

      it('renders the iframe', () => {
        expect(findIframe().attributes('src')).toBe(
          'https://embed.figma.com/design/abc?embed-host=gitlab',
        );
      });

      it('moves focus to the iframe', () => {
        expect(document.activeElement).toBe(findIframe().element);
      });

      it("applies the node's provider sandbox", () => {
        expect(findIframe().attributes('sandbox')).toBe(FIGMA_SANDBOX);
      });

      it('renders the selection overlay', () => {
        expect(findOverlay().exists()).toBe(true);
      });

      describe('when the embed changes to another source', () => {
        beforeEach(async () => {
          await wrapper.setProps({
            node: {
              attrs: {
                src: 'https://embed.figma.com/design/xyz?embed-host=gitlab',
                providerId: 'figma',
              },
            },
          });
        });

        it('requires activation again', () => {
          expect(findIframe().exists()).toBe(false);
          expect(findPlaceholder().exists()).toBe(true);
        });
      });

      describe('when other attributes of the embed change', () => {
        beforeEach(async () => {
          await wrapper.setProps({
            node: {
              attrs: {
                src: 'https://embed.figma.com/design/abc?embed-host=gitlab',
                providerId: 'figma',
                alt: 'Renamed',
              },
            },
          });
        });

        it('keeps the content loaded', () => {
          expect(findIframe().exists()).toBe(true);
        });
      });
    });

    describe('when selected', () => {
      beforeEach(() => {
        createWrapper(
          { src: 'https://embed.figma.com/design/abc?embed-host=gitlab', providerId: 'figma' },
          { selected: true },
        );
      });

      it('shows the resize handles around the placeholder', () => {
        expect(findResizeHandles()).toHaveLength(4);
        findResizeHandles().wrappers.forEach((handle) => expect(handle.isVisible()).toBe(true));
      });
    });
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

  describe('when no dimensions are set', () => {
    beforeEach(() => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123' });
    });

    it('defaults to 560 by 315', () => {
      expect(findIframe().attributes()).toMatchObject({ width: '560', height: '315' });
      expect(wrapper.vm.iframeStyle).toEqual({
        aspectRatio: '560 / 315',
        height: 'auto',
        maxHeight: 'min(80vh, 315px)',
        maxWidth: '100%',
      });
    });

    it('sizes the external content chrome to match', () => {
      expect(findExternalContent().props()).toMatchObject({ width: '560', height: '315' });
    });
  });

  describe('layout', () => {
    beforeEach(() => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123', width: '560', height: '315' });
    });

    it('lays the node out as a block, without stretching the embed', () => {
      expect(wrapper.classes()).toEqual(expect.arrayContaining(['gl-flex', 'gl-items-start']));
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

    describe('when the content has not been activated', () => {
      beforeEach(() => {
        createWrapper(
          { src: 'https://embed.figma.com/design/abc?embed-host=gitlab', providerId: 'figma' },
          { selected: true },
        );
        jest
          .spyOn(findEmbed().element, 'getBoundingClientRect')
          .mockReturnValue({ width: 560, height: 315 });
        Object.defineProperty(wrapper.element, 'clientWidth', { value: 800 });
      });

      describe('when dragged narrower', () => {
        beforeEach(() => {
          drag(200, 60);
        });

        it('resizes from the placeholder', () => {
          expect(savedSize()).toEqual({ width: 420, height: 236 });
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

    it('drags the whole embed for ProseMirror node dragging', () => {
      createWrapper({ src: 'https://www.youtube.com/embed/abc123' });

      expect(findEmbed().attributes()).toMatchObject({ draggable: 'true', 'data-drag-handle': '' });
      expect(findEmbed().element.contains(findOverlay().element)).toBe(true);
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
