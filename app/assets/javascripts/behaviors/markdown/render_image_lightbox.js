import Vue from 'vue';
import { __ } from '~/locale';
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

    newLink.setAttribute('role', 'button');
    newLink.setAttribute('aria-label', __('View image'));
    newLink.setAttribute('aria-haspopup', 'dialog');
    newLink.style.cursor = 'zoom-in';
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
