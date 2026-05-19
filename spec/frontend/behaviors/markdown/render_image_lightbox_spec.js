import waitForPromises from 'helpers/wait_for_promises';
import {
  renderImageLightbox,
  destroyImageLightbox,
} from '~/behaviors/markdown/render_image_lightbox';

jest.mock('~/behaviors/components/image_lightbox.vue', () => ({
  name: 'MockImageLightbox',
  props: {
    visible: Boolean,
    images: Array,
    startingImage: Number,
  },
  render(h) {
    return h('div', {
      class: 'mock-lightbox',
    });
  },
}));

describe('render_image_lightbox', () => {
  let container;
  let mockImages;

  const createMockImage = ({ src, alt = '', parentIsLink = true, validExtension = true }) => {
    const img = document.createElement('img');
    img.src = src;
    img.alt = alt;

    if (parentIsLink) {
      const link = document.createElement('a');
      const imageSrc = validExtension ? `${src}.jpg` : `${src}.pdf`;
      link.href = imageSrc;
      link.appendChild(img);
      container.appendChild(link);
    } else {
      container.appendChild(img);
    }

    return img;
  };

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
  });

  afterEach(() => {
    destroyImageLightbox(container);
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  describe('renderImageLightbox', () => {
    describe('with valid images', () => {
      beforeEach(() => {
        mockImages = [
          createMockImage({ src: 'http://example.com/image1', alt: 'First image' }),
          createMockImage({ src: 'http://example.com/image2', alt: 'Second image' }),
          createMockImage({ src: 'http://example.com/image3', alt: '' }),
        ];
      });

      it('creates a lightbox instance with correct images', () => {
        const createElementSpy = jest.spyOn(document, 'createElement');
        renderImageLightbox(mockImages, container);

        expect(createElementSpy).toHaveBeenCalledWith('div');

        expect(document.body.querySelector('.mock-lightbox')).not.toBeNull();
      });

      it('replaces original links with lightbox links', () => {
        const originalLinks = mockImages.map((img) => img.parentElement);

        renderImageLightbox(mockImages, container);

        const newLinks = container.querySelectorAll('a');
        newLinks.forEach((link, index) => {
          expect(link).not.toBe(originalLinks[index]);
          expect(link.style.cursor).toBe('zoom-in');
        });
      });

      it('adds click event listeners and accessibility attributes to image links', () => {
        const expectedAlts = mockImages.map((img) => img.alt);

        renderImageLightbox(mockImages, container);

        const links = container.querySelectorAll('a');
        expect(links).toHaveLength(mockImages.length);

        links.forEach((link, index) => {
          expect(link.style.cursor).toBe('zoom-in');
          expect(link.hasAttribute('role')).toBe(false);
          expect(link.hasAttribute('aria-label')).toBe(false);
          expect(link.getAttribute('aria-description')).toBe('Click to view image in full screen');
          expect(link.getAttribute('aria-haspopup')).toBe('dialog');
          expect(link.querySelector('img').alt).toBe(expectedAlts[index]);
        });
      });
    });

    describe('with invalid images', () => {
      it('skips images without anchor parent', () => {
        mockImages = [
          createMockImage({ src: 'http://example.com/image1', alt: 'Valid image' }),
          createMockImage({
            src: 'http://example.com/image2',
            alt: 'No parent',
            parentIsLink: false,
          }),
          createMockImage({ src: 'http://example.com/image3', alt: 'Another valid' }),
        ];

        renderImageLightbox(mockImages, container);

        // Only 2 images should have click handlers
        const links = container.querySelectorAll('a[style*="zoom-in"]');
        expect(links).toHaveLength(2);
      });

      it('skips links without href', () => {
        const img = document.createElement('img');
        const link = document.createElement('a');
        link.appendChild(img);
        container.appendChild(link);

        renderImageLightbox([img], container);

        expect(link.style.cursor).not.toBe('zoom-in');
      });

      it('skips non-image file extensions', () => {
        mockImages = [
          createMockImage({
            src: 'http://example.com/document.pdf',
            alt: 'PDF',
            validExtension: false,
          }),
          createMockImage({ src: 'http://example.com/image.png', alt: 'Image' }),
        ];

        renderImageLightbox(mockImages, container);

        const links = container.querySelectorAll('a[style*="zoom-in"]');
        expect(links).toHaveLength(1);
      });

      it('handles various image extensions correctly', () => {
        const extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
        const images = [];

        extensions.forEach((ext) => {
          const img = document.createElement('img');
          const link = document.createElement('a');
          link.href = `http://example.com/image.${ext}`;
          link.appendChild(img);
          container.appendChild(link);
          images.push(img);
        });

        renderImageLightbox(images, container);

        const links = container.querySelectorAll('a[style*="zoom-in"]');
        expect(links).toHaveLength(extensions.length);
      });

      it('handles image URLs with query parameters', () => {
        container.innerHTML = '';

        const img = document.createElement('img');
        img.src = 'http://example.com/image.jpg';
        const link = document.createElement('a');
        link.href = 'http://example.com/image.jpg?size=large&quality=high';
        link.appendChild(img);
        container.appendChild(link);

        expect(container.querySelector('a')).not.toBeNull();
        expect(container.querySelector('a').href).toContain('image.jpg');

        renderImageLightbox([img], container);

        const newLink = container.querySelector('a');
        expect(newLink).not.toBeNull();
        expect(newLink.style.cursor).toBe('zoom-in');
      });

      it('skips mixed case non-image extensions', () => {
        const img = document.createElement('img');
        const link = document.createElement('a');
        link.href = 'http://example.com/document.PDF';
        link.appendChild(img);
        container.appendChild(link);

        renderImageLightbox([img], container);

        expect(link.style.cursor).not.toBe('zoom-in');
      });
    });

    describe('with empty inputs', () => {
      it('handles empty array of elements', () => {
        expect(() => {
          renderImageLightbox([], container);
        }).not.toThrow();

        expect(document.body.querySelector('.mock-lightbox')).toBeNull();
      });

      it('returns early when no valid images found', () => {
        const img = document.createElement('img');
        container.appendChild(img);

        renderImageLightbox([img], container);

        expect(document.body.querySelector('.mock-lightbox')).toBeNull();
      });
    });

    describe('instance management', () => {
      it('reuses existing instance for the same container', () => {
        const images1 = [createMockImage({ src: 'http://example.com/image1', alt: 'First' })];
        const images2 = [
          createMockImage({ src: 'http://example.com/image2', alt: 'Second' }),
          createMockImage({ src: 'http://example.com/image3', alt: 'Third' }),
        ];

        renderImageLightbox(images1, container);
        const firstInstance = document.body.querySelector('.mock-lightbox');

        images2.forEach((img) => container.appendChild(img.parentElement));

        renderImageLightbox(images2, container);
        const secondInstance = document.body.querySelector('.mock-lightbox');

        expect(firstInstance).toBe(secondInstance);
        expect(document.body.querySelectorAll('.mock-lightbox')).toHaveLength(1);
      });

      it('creates separate instances for different containers', () => {
        const container2 = document.createElement('div');
        document.body.appendChild(container2);

        const images1 = [createMockImage({ src: 'http://example.com/image1', alt: 'First' })];
        const img2 = document.createElement('img');
        const link2 = document.createElement('a');
        link2.href = 'http://example.com/image2.jpg';
        link2.appendChild(img2);
        container2.appendChild(link2);

        renderImageLightbox(images1, container);
        renderImageLightbox([img2], container2);

        expect(document.body.querySelectorAll('.mock-lightbox')).toHaveLength(2);

        destroyImageLightbox(container2);
        container2.remove();
      });
    });

    describe('lightbox interaction', () => {
      it('passes correct image data to lightbox component', () => {
        const images = [];

        container.innerHTML = '';

        for (let i = 1; i <= 2; i += 1) {
          const img = document.createElement('img');
          img.src = `http://example.com/image${i}.jpg`;
          img.alt = `Alt ${i}`;

          const link = document.createElement('a');
          link.href = `http://example.com/image${i}.jpg`;
          link.appendChild(img);
          container.appendChild(link);
          images.push(img);
        }

        renderImageLightbox(images, container);

        const links = container.querySelectorAll('a');

        expect(links).toHaveLength(2);
        links.forEach((link) => {
          expect(link.style.cursor).toBe('zoom-in');
          expect(link.hasAttribute('role')).toBe(false);
          expect(link.hasAttribute('aria-label')).toBe(false);
          expect(link.getAttribute('aria-description')).toBe('Click to view image in full screen');
          expect(link.getAttribute('aria-haspopup')).toBe('dialog');
        });
      });
    });
  });

  describe('destroyImageLightbox', () => {
    it('destroys Vue instance and removes DOM element', () => {
      const images = [createMockImage({ src: 'http://example.com/image1', alt: 'Image' })];
      renderImageLightbox(images, container);

      const lightboxEl = document.body.querySelector('.mock-lightbox');
      expect(lightboxEl).not.toBeNull();

      destroyImageLightbox(container);

      expect(document.body.querySelector('.mock-lightbox')).toBeNull();
    });

    it('handles destroying non-existent instance gracefully', () => {
      const newContainer = document.createElement('div');

      expect(() => {
        destroyImageLightbox(newContainer);
      }).not.toThrow();
    });

    it('removes instance from WeakMap', () => {
      const images = [createMockImage({ src: 'http://example.com/image1', alt: 'Image' })];
      renderImageLightbox(images, container);

      destroyImageLightbox(container);

      // Trying to destroy again should not throw
      expect(() => {
        destroyImageLightbox(container);
      }).not.toThrow();
    });

    it('only destroys instance for specific container', () => {
      const container2 = document.createElement('div');
      document.body.appendChild(container2);

      const images1 = [createMockImage({ src: 'http://example.com/image1', alt: 'Image 1' })];
      const img2 = document.createElement('img');
      const link2 = document.createElement('a');
      link2.href = 'http://example.com/image2.jpg';
      link2.appendChild(img2);
      container2.appendChild(link2);

      renderImageLightbox(images1, container);
      renderImageLightbox([img2], container2);

      expect(document.body.querySelectorAll('.mock-lightbox')).toHaveLength(2);

      destroyImageLightbox(container);

      expect(document.body.querySelectorAll('.mock-lightbox')).toHaveLength(1);

      destroyImageLightbox(container2);
      container2.remove();
    });
  });

  describe('transparency toggle', () => {
    const createTransparentImage = (src) => {
      const img = document.createElement('img');
      img.src = src;

      const link = document.createElement('a');
      link.href = src;
      link.appendChild(img);
      container.appendChild(link);

      return img;
    };

    const mockImageLoadWithTransparency = (transparentPixelCount = 0) => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const fakeImg = {
          srcValue: '',
          set src(val) {
            fakeImg.srcValue = val;
            fakeImg.naturalWidth = 10;
            fakeImg.naturalHeight = 10;
            Promise.resolve()
              .then(() => {
                if (fakeImg.onload) fakeImg.onload();
              })
              .catch(() => {});
          },
          get src() {
            return fakeImg.srcValue;
          },
        };
        return fakeImg;
      });

      const pixelData = new Uint8ClampedArray(10 * 10 * 4).fill(255);
      for (let i = 0; i < transparentPixelCount; i += 1) {
        pixelData[i * 4 + 3] = 0;
      }

      jest.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue({
        drawImage: jest.fn(),
        getImageData: () => ({ data: pixelData }),
      });
    };

    const renderWithTransparency = async (
      src = 'http://example.com/image.png',
      transparentPixelCount = 5,
    ) => {
      mockImageLoadWithTransparency(transparentPixelCount);
      const img = createTransparentImage(src);
      renderImageLightbox([img], container);
      await waitForPromises();
    };

    describe('createTransparencyToggle', () => {
      it('toggles md-img-checkerboard class on image when clicked', async () => {
        const checkerboardClass = 'md-img-checkerboard';

        await renderWithTransparency();

        const button = container.querySelector('button');
        const toggleImg = container.querySelector('img');

        expect(toggleImg.classList.contains(checkerboardClass)).toBe(false);

        button.click();
        expect(toggleImg.classList.contains(checkerboardClass)).toBe(true);

        button.click();
        expect(toggleImg.classList.contains(checkerboardClass)).toBe(false);
      });
    });

    describe('addToggleToImage', () => {
      beforeEach(async () => {
        await renderWithTransparency();
      });

      it('sets data-transparency-toggle attribute on the wrapping element', () => {
        const wrapper = container.querySelector('[data-transparency-toggle]');
        expect(wrapper.dataset.transparencyToggle).toBe('true');
      });

      it('does not double-wrap when called twice', async () => {
        const wrappersBefore = container.querySelectorAll('[data-transparency-toggle]');
        expect(wrappersBefore).toHaveLength(1);

        const link = container.querySelector('a');
        const currentImg = link.querySelector('img');
        renderImageLightbox([currentImg], container);

        await waitForPromises();

        const wrappersAfter = container.querySelectorAll('[data-transparency-toggle]');
        expect(wrappersAfter).toHaveLength(1);
      });

      it('places the button as a sibling of the link inside the wrapper', () => {
        const wrapper = container.querySelector('[data-transparency-toggle]');
        expect(wrapper.querySelector('a')).not.toBeNull();
        expect(wrapper.querySelector('button')).not.toBeNull();
      });
    });

    describe('supportsTransparency', () => {
      it.each(['png', 'webp', 'gif'])(
        'detects .%s as a transparency-capable format',
        async (ext) => {
          await renderWithTransparency(`http://example.com/image.${ext}`);

          expect(container.querySelector('[data-transparency-toggle]')).not.toBeNull();
        },
      );

      it.each(['jpg', 'jpeg', 'bmp'])('does not add toggle for .%s images', async (ext) => {
        await renderWithTransparency(`http://example.com/image.${ext}`);

        expect(container.querySelector('[data-transparency-toggle]')).toBeNull();
      });

      it('handles URLs with query parameters', async () => {
        await renderWithTransparency('http://example.com/image.png?size=large');

        expect(container.querySelector('[data-transparency-toggle]')).not.toBeNull();
      });
    });

    describe('hasTransparency', () => {
      it('does not add toggle when image has no transparent pixels', async () => {
        await renderWithTransparency('http://example.com/opaque.png', 0);

        expect(container.querySelector('[data-transparency-toggle]')).toBeNull();
      });

      it('does not add toggle when transparency is below 5% threshold', async () => {
        await renderWithTransparency('http://example.com/negligible.png', 4);

        expect(container.querySelector('[data-transparency-toggle]')).toBeNull();
      });

      it('adds toggle when transparency meets 5% threshold', async () => {
        await renderWithTransparency('http://example.com/transparent.png', 5);

        expect(container.querySelector('[data-transparency-toggle]')).not.toBeNull();
      });

      it('adds toggle when image has significant transparent pixels', async () => {
        await renderWithTransparency('http://example.com/transparent.png', 10);

        expect(container.querySelector('[data-transparency-toggle]')).not.toBeNull();
      });

      it('handles image load errors gracefully', async () => {
        jest.spyOn(window, 'Image').mockImplementation(() => {
          const fakeImg = {
            set src(_) {
              Promise.resolve()
                .then(() => {
                  if (fakeImg.onerror) fakeImg.onerror();
                })
                .catch(() => {});
            },
          };
          return fakeImg;
        });

        const img = createTransparentImage('http://example.com/broken.png');
        renderImageLightbox([img], container);

        await waitForPromises();

        expect(container.querySelector('[data-transparency-toggle]')).toBeNull();
      });
    });
  });
});
