import { GlIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ImageLightbox from '~/behaviors/components/image_lightbox.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('ImageLightbox', () => {
  let wrapper;

  const defaultImages = [
    { imageSrc: 'https://example.com/image1.jpg', imageAlt: 'First image' },
    { imageSrc: 'https://example.com/image2.png', imageAlt: 'Second image' },
    { imageSrc: 'https://example.com/image3.gif', imageAlt: 'Third image' },
  ];

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(ImageLightbox, {
      propsData: {
        images: defaultImages,
        ...props,
      },
      stubs: {
        ClipboardButton: true,
        GlButton: true,
        GlButtonGroup: true,
        GlIcon: true,
      },
    });
  };

  const findCloseButton = () => wrapper.find('#image-lightbox-close');
  const findDownloadButton = () => wrapper.findComponent('[icon="download"]');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findPrevButton = () => wrapper.findComponent('[icon="chevron-lg-left"]');
  const findNextButton = () => wrapper.findComponent('[icon="chevron-lg-right"]');
  const findImage = () => wrapper.find('img');
  const findErrorIcon = () => wrapper.findComponent(GlIcon);
  const findLightboxContainer = () => wrapper.find('#lightbox');

  describe('visibility', () => {
    describe('when not visible', () => {
      beforeEach(() => {
        createComponent({ visible: false });
      });

      it('does not render the lightbox', () => {
        expect(findLightboxContainer().exists()).toBe(false);
      });
    });

    describe('when visible', () => {
      beforeEach(() => {
        createComponent({ visible: true });
      });

      it('renders the lightbox', () => {
        expect(findLightboxContainer().exists()).toBe(true);
      });

      it('adds body class when mounted', () => {
        expect(document.body.classList.contains('image-lightbox-open')).toBe(true);
      });

      it('adds keydown event listener', () => {
        const addEventListenerSpy = jest.spyOn(document, 'addEventListener');
        createComponent({ visible: true });

        expect(addEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function));
      });
    });
  });

  describe('image display', () => {
    beforeEach(() => {
      createComponent({ visible: true, startingImage: 0 }, mount);
    });

    it('displays the current image with correct src and alt', async () => {
      await nextTick();
      const image = findImage();
      expect(image.element.src).toBe(defaultImages[0].imageSrc);
      expect(image.element.alt).toBe(defaultImages[0].imageAlt);
    });

    describe('error state', () => {
      it('shows error message when imageSrc is null', () => {
        createComponent(
          {
            visible: true,
            images: [{ imageSrc: null, imageAlt: 'No image' }],
          },
          mount,
        );

        expect(findErrorIcon().exists()).toBe(true);
        expect(wrapper.text()).toContain('Image could not be loaded.');
      });

      it('shows error message when image fails to load', async () => {
        createComponent({ visible: true }, mount);

        const image = findImage();
        await image.trigger('error');

        expect(findErrorIcon().exists()).toBe(true);
        expect(wrapper.text()).toContain('Image could not be loaded.');
      });
    });
  });

  describe('navigation', () => {
    beforeEach(() => {
      createComponent({ visible: true, startingImage: 1 });
    });

    describe('previous button', () => {
      it('navigates to previous image when clicked', async () => {
        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(findImage().element.src).toBe(defaultImages[0].imageSrc);
        expect(findImage().element.alt).toBe(defaultImages[0].imageAlt);
      });

      it('is disabled when on first image', async () => {
        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(findPrevButton().props('disabled')).toBe(true);
      });

      it('is enabled when not on first image', () => {
        expect(findPrevButton().props('disabled')).toBe(false);
      });
    });

    describe('next button', () => {
      it('navigates to next image when clicked', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        expect(findImage().element.src).toBe(defaultImages[2].imageSrc);
        expect(findImage().element.alt).toBe(defaultImages[2].imageAlt);
      });

      it('is disabled when on last image', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        expect(findNextButton().props('disabled')).toBe(true);
      });

      it('is enabled when not on last image', () => {
        expect(findNextButton().props('disabled')).toBe(false);
      });
    });

    describe('when only one image', () => {
      beforeEach(() => {
        createComponent({
          visible: true,
          images: [defaultImages[0]],
        });
      });

      it('does not show navigation buttons', () => {
        expect(findPrevButton().exists()).toBe(false);
        expect(findNextButton().exists()).toBe(false);
      });
    });
  });

  describe('keyboard navigation', () => {
    beforeEach(() => {
      createComponent({ visible: true, startingImage: 1 });
    });

    it('closes on Escape key', async () => {
      const event = new KeyboardEvent('keydown', { key: 'Escape' });
      document.dispatchEvent(event);
      await nextTick();

      expect(findLightboxContainer().exists()).toBe(false);
      expect(wrapper.emitted('change')).toEqual([[false]]);
    });

    it('navigates to previous image on ArrowLeft key', async () => {
      const event = new KeyboardEvent('keydown', { key: 'ArrowLeft' });
      document.dispatchEvent(event);
      await nextTick();

      expect(findImage().element.src).toBe(defaultImages[0].imageSrc);
      expect(findImage().element.alt).toBe(defaultImages[0].imageAlt);
    });

    it('navigates to next image on ArrowRight key', async () => {
      const event = new KeyboardEvent('keydown', { key: 'ArrowRight' });
      document.dispatchEvent(event);
      await nextTick();

      expect(findImage().element.src).toBe(defaultImages[2].imageSrc);
      expect(findImage().element.alt).toBe(defaultImages[2].imageAlt);
    });
  });

  describe('toolbar actions', () => {
    beforeEach(() => {
      createComponent({ visible: true });
    });

    describe('close button', () => {
      it('closes the lightbox when clicked', async () => {
        findCloseButton().vm.$emit('click');
        await nextTick();

        expect(findLightboxContainer().exists()).toBe(false);
        expect(wrapper.emitted('change')).toEqual([[false]]);
      });

      it('removes body class when closing', async () => {
        findCloseButton().vm.$emit('click');
        await nextTick();

        expect(document.body.classList.contains('image-lightbox-open')).toBe(false);
      });

      it('removes keydown listener when closing', async () => {
        const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');
        findCloseButton().vm.$emit('click');
        await nextTick();

        expect(removeEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function));
      });
    });

    describe('clipboard button', () => {
      it('passes correct props', () => {
        const clipboardButton = findClipboardButton();

        expect(clipboardButton.props()).toMatchObject({
          category: 'tertiary',
          icon: 'link',
          text: defaultImages[0].imageSrc,
          title: 'Copy image link',
          tooltipPlacement: 'bottom',
        });
      });
    });

    describe('download button', () => {
      it('has correct attributes for download', () => {
        const downloadButton = findDownloadButton();

        expect(downloadButton.props('icon')).toBe('download');
        expect(downloadButton.attributes('href')).toBe(defaultImages[0].imageSrc);
        expect(downloadButton.attributes('download')).toBe('image1.jpg');
        expect(downloadButton.attributes('title')).toBe('Download');
      });

      describe('filename extraction', () => {
        it('extracts filename from URL path', () => {
          createComponent({
            visible: true,
            images: [
              {
                imageSrc: 'https://example.com/path/to/my-image.png?query=param',
                imageAlt: 'Test',
              },
            ],
          });

          expect(findDownloadButton().attributes('download')).toBe('my-image.png');
        });

        it('handles relative URLs', () => {
          createComponent({
            visible: true,
            images: [{ imageSrc: '/uploads/relative-image.gif', imageAlt: 'Test' }],
          });

          expect(findDownloadButton().attributes('download')).toBe('relative-image.gif');
        });
      });
    });
  });

  describe('clicking on backdrop', () => {
    beforeEach(() => {
      createComponent({ visible: true });
    });

    it('closes lightbox when clicking on image container', async () => {
      const imageContainer = wrapper.find('.gl-cursor-zoom-out');
      imageContainer.trigger('click');
      await nextTick();

      expect(findLightboxContainer().exists()).toBe(false);
      expect(wrapper.emitted('change')).toEqual([[false]]);
    });

    it('closes lightbox when clicking on header', async () => {
      const header = wrapper.find('.gl-flex.gl-w-full.gl-items-center');
      header.trigger('click');
      await nextTick();

      expect(findLightboxContainer().exists()).toBe(false);
      expect(wrapper.emitted('change')).toEqual([[false]]);
    });
  });

  describe('focus', () => {
    it('focuses close button when becoming visible', async () => {
      const focusSpy = jest.fn();
      const mockElement = { focus: focusSpy };

      document.getElementById = jest.fn((id) => {
        if (id === 'image-lightbox-close') return mockElement;
        return null;
      });

      createComponent({ visible: false });
      await wrapper.setProps({ visible: true });
      await nextTick();
      await nextTick(); // wait for the nextTick used in focusLightbox()

      expect(focusSpy).toHaveBeenCalled();
    });
  });
});
