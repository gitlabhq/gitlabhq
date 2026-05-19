import Vue from 'vue';
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { renderVueComponentForLegacyJS } from '~/render_vue_component_for_legacy_js';
import ImageLightbox from '~/behaviors/components/image_lightbox.vue';
import { IMAGE_FORMATS } from '~/lib/utils/constants';

const lightboxInstances = new WeakMap();

function createLightboxInstance(container, images) {
  // Check if instance already exists for this container
  if (lightboxInstances.has(container)) {
    const instance = lightboxInstances.get(container);
    instance.images = images;
    return instance;
  }

  const app = new Vue({
    el: document.createElement('div'),
    name: 'ImageLightboxRoot',
    data() {
      return {
        lightboxVisible: false,
        showImage: 0,
        images: images || [],
      };
    },
    methods: {
      show(imageIndex = 0) {
        this.showImage = imageIndex;
        this.lightboxVisible = true;
      },
    },
    render(createElement) {
      return createElement(ImageLightbox, {
        props: {
          visible: this.lightboxVisible,
          images: this.images,
          startingImage: this.showImage,
        },
        on: {
          change: (visible) => {
            this.lightboxVisible = visible;
          },
        },
      });
    },
  });

  document.body.appendChild(app.$el);

  lightboxInstances.set(container, app);

  return app;
}

function buildImages(imgs) {
  const images = [];
  const imageLinks = [];

  imgs.forEach((img) => {
    const link = img.parentElement;

    // Because we rely on image link (to avoid lazy loading issues), skip if parent is not a link or has no href
    if (!link || link.tagName !== 'A' || !link.href) {
      return;
    }
    const filename = link.href.split('/').pop().split('?')[0];
    const isImageUrl = IMAGE_FORMATS.test(filename);

    if (!isImageUrl) {
      return;
    }

    const imageObj = {
      imageSrc: link.href,
      imageAlt: img.alt || '',
    };

    images.push(imageObj);
    imageLinks.push({ img, link, index: images.length - 1 });
  });

  return { images, imageLinks };
}

function createTransparencyToggle(img) {
  const button = renderVueComponentForLegacyJS(GlButton, {
    class:
      'has-tooltip gl-absolute gl-top-2 gl-right-2 gl-z-1 gl-opacity-0 gl-transition-opacity group-hover:gl-opacity-5 hover:!gl-opacity-10 focus:!gl-opacity-10',
    props: {
      icon: 'dot-grid',
      size: 'small',
    },
    attrs: {
      'data-title': __('Toggle transparency checkerboard'),
      'aria-label': __('Toggle transparency checkerboard'),
    },
  });

  button.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    img.classList.toggle('md-img-checkerboard');
  });

  return button;
}

const TRANSPARENT_IMAGE_FORMATS = /\.(png|webp|gif)(\?.*)?$/i;
const ANALYZE_MAX_SIZE = 100;
const TRANSPARENCY_THRESHOLD = 0.05;

function supportsTransparency(link) {
  const filename = link.href?.split('/').pop() || '';
  return TRANSPARENT_IMAGE_FORMATS.test(filename);
}

function checkPixelsForTransparency(img) {
  const canvas = document.createElement('canvas');
  const scale = Math.min(1, ANALYZE_MAX_SIZE / Math.max(img.naturalWidth, img.naturalHeight));
  const width = Math.max(1, Math.floor(img.naturalWidth * scale));
  const height = Math.max(1, Math.floor(img.naturalHeight * scale));

  canvas.width = width;
  canvas.height = height;

  const ctx = canvas.getContext('2d');
  ctx.drawImage(img, 0, 0, width, height);

  const { data } = ctx.getImageData(0, 0, width, height);
  const totalPixels = width * height;
  if (totalPixels === 0) return false;

  const threshold = Math.ceil(totalPixels * TRANSPARENCY_THRESHOLD);
  let transparentCount = 0;

  for (let i = 3; i < data.length; i += 4) {
    if (data[i] < 255) {
      transparentCount += 1;
      if (transparentCount === threshold) return true;
    }
  }

  return false;
}

function hasTransparency(imageSrc) {
  return new Promise((resolve) => {
    const testImg = new Image();
    // Only set crossOrigin for cross-domain images to avoid unnecessary CORS issues
    if (new URL(imageSrc, window.location.href).origin !== window.location.origin) {
      testImg.crossOrigin = 'anonymous';
    }

    testImg.onload = () => {
      try {
        resolve(checkPixelsForTransparency(testImg));
      } catch (e) {
        resolve(false);
      }
    };

    testImg.onerror = () => {
      resolve(false);
    };

    testImg.src = imageSrc;
  });
}

function addToggleToImage(link, img) {
  if (link.parentNode.dataset.transparencyToggle) return;

  const wrapper = document.createElement('span');
  wrapper.className = 'gl-relative gl-inline-block gl-group';
  wrapper.dataset.transparencyToggle = 'true';

  link.parentNode.insertBefore(wrapper, link);
  wrapper.appendChild(link);
  wrapper.appendChild(createTransparencyToggle(img));
}

function wrapImageWithToggle(link) {
  if (!supportsTransparency(link)) return;

  const img = link.querySelector('img');
  if (!img) return;

  hasTransparency(link.href)
    .then((transparent) => {
      if (transparent) {
        addToggleToImage(link, img);
      }
    })
    .catch(() => {});
}

export function renderImageLightbox(els, container) {
  if (!els.length) return;

  const { images, imageLinks } = buildImages(els);

  if (images.length === 0) return;

  const lightboxInstance = createLightboxInstance(container, images);

  imageLinks.forEach(({ link, index }) => {
    const newLink = link.cloneNode(true);
    link.parentNode.replaceChild(newLink, link);

    newLink.addEventListener('click', (e) => {
      if (e.metaKey || e.ctrlKey || e.altKey) {
        return;
      }
      e.preventDefault();
      lightboxInstance.show(index);
    });

    newLink.setAttribute('aria-description', __('Click to view image in full screen'));
    newLink.setAttribute('aria-haspopup', 'dialog');
    newLink.style.cursor = 'zoom-in';

    wrapImageWithToggle(newLink);
  });
}

export function destroyImageLightbox(element) {
  if (lightboxInstances.has(element)) {
    const instance = lightboxInstances.get(element);
    instance.$destroy();
    instance.$el.remove();
    lightboxInstances.delete(element);
  }
}
