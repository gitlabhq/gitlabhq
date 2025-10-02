<script>
import { GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { __ } from '~/locale';

export default {
  name: 'ImageLightbox',

  components: {
    ClipboardButton,
    GlButton,
    GlButtonGroup,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    images: {
      type: Array,
      required: true,
      default() {
        return [];
      },
    },
    startingImage: {
      type: Number,
      required: false,
      default: 0,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  data() {
    return {
      currentImage: this.startingImage,
      isVisible: this.visible,
      imageLoaded: false,
      imageError: false,
      previouslyFocusedElement: null,
    };
  },
  computed: {
    imageSrc() {
      return this.images[this.currentImage]?.imageSrc;
    },
    imageAlt() {
      return this.images[this.currentImage]?.imageAlt;
    },
    imageFilename() {
      let filename = 'image';

      try {
        const url = new URL(this.imageSrc, window.location.origin);
        const { pathname } = url;
        const pathParts = pathname.split('/');
        const lastPart = pathParts[pathParts.length - 1];

        [filename] = lastPart.split('?');
      } catch (e) {
        filename = 'image.png';
      }

      return filename;
    },
  },
  watch: {
    visible(newVal) {
      this.isVisible = newVal;

      if (newVal) {
        this.previouslyFocusedElement = document.activeElement;
        this.addBodyClass();
        this.$nextTick(() => {
          this.addKeydownListener();
          this.focusLightbox();
          this.setupFocusTrap();
        });
      } else {
        this.removeBodyClass();
        this.removeKeydownListener();
        this.removeFocusTrap();
        if (this.previouslyFocusedElement) {
          this.previouslyFocusedElement.focus();
        }
      }
    },
    startingImage(newVal) {
      if (newVal !== null && newVal !== undefined) {
        this.currentImage = newVal;
      }
    },
  },
  mounted() {
    if (this.isVisible) {
      this.previouslyFocusedElement = document.activeElement;
      this.addBodyClass();
      this.addKeydownListener();
      this.focusLightbox();
      this.setupFocusTrap();
    }
  },
  beforeDestroy() {
    this.removeBodyClass();
    this.removeKeydownListener();
    this.removeFocusTrap();
  },
  methods: {
    close() {
      this.isVisible = false;
      this.$emit('change', false);
      this.removeBodyClass();
      this.removeKeydownListener();
      this.removeFocusTrap();
      // Restore focus
      if (this.previouslyFocusedElement) {
        this.previouslyFocusedElement.focus();
        this.previouslyFocusedElement = null;
      }
    },
    onImageLoad() {
      this.imageLoaded = true;
      this.imageError = false;
    },
    onImageError() {
      this.imageError = true;
    },
    handleKeydown(event) {
      // Limit events to those applicable in the lightbox
      event.stopPropagation();
      event.stopImmediatePropagation();
      if (event.key === 'Escape') {
        this.close();
      } else if (event.key === 'ArrowLeft') {
        this.prevImage();
      } else if (event.key === 'ArrowRight') {
        this.nextImage();
      } else if (event.key === 'Tab') {
        this.handleTabKey(event);
      } else if (event.key !== 'Enter' && event.key !== 'Space') {
        // Allow enter/space as button press
        event.preventDefault();
      }
    },
    handleTabKey(event) {
      const focusableElements = this.getFocusableElements();

      if (focusableElements.length === 0) return;

      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      // Trap focus in the lightbox, similar to modals
      if (event.shiftKey) {
        if (document.activeElement === firstElement) {
          event.preventDefault();
          lastElement.focus();
        }
      } else if (document.activeElement === lastElement) {
        event.preventDefault();
        firstElement.focus();
      }
    },
    getFocusableElements() {
      const toolbar = this.$el?.querySelector('.js-image-lightbox-toolbar');
      if (!toolbar) return [];

      return Array.from(
        toolbar.querySelectorAll('button:not([disabled]), a[href]:not([disabled])'),
      );
    },
    setupFocusTrap() {
      const lightbox = this.$el;
      if (lightbox) {
        lightbox.setAttribute('role', 'dialog');
        lightbox.setAttribute('aria-modal', 'true');
        lightbox.setAttribute('aria-label', __('Image viewer'));
      }

      this.setInertElements(true);
    },
    removeFocusTrap() {
      this.setInertElements(false);
    },
    // Ensure elements under the lightbox are ignored
    setInertElements(inert) {
      const skipTags = new Set([
        'SCRIPT',
        'STYLE',
        'LINK',
        'META',
        'BASE',
        'TITLE',
        'NOSCRIPT',
        'TEMPLATE',
        'BR',
        'HR',
      ]);
      const bodyChildren = Array.from(document.body.children).filter(
        (child) => !skipTags.has(child.tagName) && child !== this.$el && !child.contains(this.$el),
      );
      for (let i = 0; i < bodyChildren.length; i += 1) {
        const child = bodyChildren[i];
        if (inert) {
          if (child.hasAttribute('aria-hidden')) {
            child.dataset.originalAriaHidden = child.getAttribute('aria-hidden');
          }
          child.setAttribute('aria-hidden', 'true');
          if ('inert' in child) {
            child.inert = true;
          }
        } else {
          if (child.dataset.originalAriaHidden) {
            child.setAttribute('aria-hidden', child.dataset.originalAriaHidden);
            delete child.dataset.originalAriaHidden;
          } else {
            child.removeAttribute('aria-hidden');
          }
          if ('inert' in child) {
            child.inert = false;
          }
        }
      }
    },
    addKeydownListener() {
      document.addEventListener('keydown', this.handleKeydown);
    },
    removeKeydownListener() {
      document.removeEventListener('keydown', this.handleKeydown);
    },
    addBodyClass() {
      document.body.classList.add('image-lightbox-open');
    },
    removeBodyClass() {
      document.body.classList.remove('image-lightbox-open');
    },
    focusLightbox() {
      this.$nextTick(() => {
        const target = document.getElementById('image-lightbox-close');
        if (target) {
          target.focus();
        }
      });
    },
    nextImage() {
      if (this.currentImage < this.images.length - 1) {
        this.currentImage += 1;
        this.imageLoaded = false;
        this.imageError = false;
      }
      this.$root.$emit('bv::hide::tooltip', 'next-image-btn');
    },
    prevImage() {
      if (this.currentImage > 0) {
        this.currentImage -= 1;
        this.imageLoaded = false;
        this.imageError = false;
      }
      this.$root.$emit('bv::hide::tooltip', 'prev-image-btn');
    },
  },
};
</script>
<template>
  <div
    v-if="isVisible"
    id="lightbox"
    class="image-lightbox gl-fixed gl-left-0 gl-top-0 gl-z-[1040] gl-flex gl-h-full gl-w-full gl-flex-col gl-overflow-hidden gl-bg-default"
  >
    <div
      class="js-image-lightbox-toolbar gl-flex gl-w-full gl-items-center gl-justify-end gl-gap-3 gl-bg-overlap gl-p-3"
      @click.self="close"
    >
      <div class="gl-flex gl-gap-2">
        <clipboard-button
          category="tertiary"
          icon="link"
          :text="imageSrc || ''"
          :title="__('Copy image link')"
          tooltip-placement="bottom"
        />
        <gl-button
          v-gl-tooltip.bottom
          category="tertiary"
          icon="download"
          :title="__('Download')"
          :aria-label="__('Download')"
          :href="imageSrc"
          :download="imageFilename"
        />

        <gl-button-group v-if="images.length > 1" class="gl-pl-5">
          <gl-button
            id="prev-image-btn"
            v-gl-tooltip.bottom
            :disabled="currentImage === 0"
            icon="chevron-lg-left"
            :title="__('Previous image')"
            :aria-label="__('Previous image')"
            @click="prevImage"
          />
          <gl-button
            id="next-image-btn"
            v-gl-tooltip.bottom
            :disabled="currentImage === images.length - 1"
            icon="chevron-lg-right"
            :title="__('Next image')"
            :aria-label="__('Next image')"
            @click="nextImage"
          />
        </gl-button-group>
      </div>
      <gl-button
        id="image-lightbox-close"
        category="tertiary"
        icon="close"
        :aria-label="__('Close')"
        @click="close"
      />
    </div>
    <div class="gl-flex gl-min-h-0 gl-flex-1 gl-cursor-zoom-out gl-flex-col" @click="close">
      <div
        class="gl-flex gl-max-h-full gl-min-h-0 gl-flex-1 gl-items-center gl-justify-center gl-overflow-auto gl-p-3"
      >
        <img
          v-if="imageSrc && !imageError"
          :src="imageSrc"
          :alt="imageAlt"
          class="gl-h-auto gl-max-h-full gl-w-auto gl-max-w-full gl-object-contain"
          @load="onImageLoad"
          @error="onImageError"
        />
        <div v-if="!imageSrc || imageError" class="gl-flex gl-flex-col gl-items-center gl-gap-3">
          <gl-icon name="error" variant="danger" class="gl-block" />
          <p>{{ __('Image could not be loaded.') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
