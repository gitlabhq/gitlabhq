<script>
import { s__ } from '~/locale';
import { getScrollingElement } from '~/lib/utils/panels';
import {
  scrollToElement,
  resolveScrollContainer,
  computeActiveSection,
} from '~/lib/utils/scroll_utils';

export default {
  name: 'PageNavigationMenu',
  components: {},
  props: {
    title: {
      type: String,
      required: false,
      default: () => s__('PageNavigation|On this page'),
    },
    items: {
      type: Array,
      required: true,
      validator: (items) => items.every((item) => item.id && item.label),
    },
    scrollOffset: {
      type: Number,
      required: false,
      default: -10,
    },
    autoUpdateDelay: {
      type: Number,
      required: false,
      default: 1500,
    },
  },
  data() {
    return {
      activeSection: null,
      scrollingElement: null,
      scrollRafId: null,
      suppressAutoUpdateUntil: 0,
    };
  },
  mounted() {
    this.setInitialActiveSection();
    this.initScrollTracking();
  },
  beforeDestroy() {
    if (this.scrollingElement) {
      this.scrollingElement.removeEventListener('scroll', this.onScroll);
    }
    if (this.scrollRafId) {
      cancelAnimationFrame(this.scrollRafId);
      this.scrollRafId = null;
    }
  },
  methods: {
    getCurrentTimestamp() {
      return typeof performance !== 'undefined' ? performance.now() : Date.now();
    },
    setInitialActiveSection() {
      if (this.items.length > 0) {
        this.activeSection = this.items[0].id;
      }
    },
    scrollToSection(sectionId) {
      const target = document.getElementById(sectionId);
      const container = getScrollingElement(target);

      if (!target || !container) return;

      scrollToElement(target, { offset: this.scrollOffset, behavior: 'smooth' });

      if (!this.scrollingElement) this.scrollingElement = container;

      this.activeSection = sectionId;

      // Update hash after initiating scroll to avoid interrupting the animation
      requestAnimationFrame(() => {
        const hash = `#${encodeURIComponent(sectionId)}`;
        window.history.pushState(null, '', hash);
      });

      // Prevent auto-tracking from overriding the clicked state during smooth scroll
      this.suppressAutoUpdateUntil = this.getCurrentTimestamp() + this.autoUpdateDelay;
    },
    isActive(itemId) {
      return this.activeSection === itemId;
    },
    initScrollTracking() {
      this.scrollingElement = resolveScrollContainer(this.items);
      if (!this.scrollingElement) return;

      this.onScroll = this.onScroll.bind(this);
      this.scrollingElement.addEventListener('scroll', this.onScroll, { passive: true });

      this.handleScroll();
    },
    onScroll() {
      if (this.scrollRafId) return;
      this.scrollRafId = requestAnimationFrame(() => {
        this.scrollRafId = null;
        this.handleScroll();
      });
    },
    handleScroll() {
      const now = this.getCurrentTimestamp();
      if (now < this.suppressAutoUpdateUntil) return;
      if (!this.scrollingElement) return;

      const currentId = computeActiveSection(this.items, this.scrollingElement);
      if (currentId && currentId !== this.activeSection) {
        this.activeSection = currentId;
      }
    },
  },
};
</script>

<template>
  <nav class="gl-sticky gl-top-5">
    <h4 class="gl-mb-4 gl-text-sm gl-text-subtle">
      {{ title }}
    </h4>
    <ul class="gl-border-l gl-m-0 gl-list-none gl-border-l-2 gl-border-default gl-p-0">
      <li v-for="item in items" :key="item.id" class="gl-mb-2">
        <a
          :class="[
            'on-this-page-link gl-relative gl-block gl-rounded-sm gl-px-4 gl-py-2 gl-text-sm gl-no-underline hover:gl-no-underline focus:gl-no-underline',
            isActive(item.id)
              ? 'is-active gl-bg-subtle gl-font-bold gl-text-default'
              : 'gl-text-secondary hover:gl-bg-subtle hover:gl-text-default',
          ]"
          :href="`#${encodeURIComponent(item.id)}`"
          :aria-current="isActive(item.id) ? 'location' : null"
          @click.prevent="scrollToSection(item.id)"
        >
          {{ item.label }}
        </a>
      </li>
    </ul>
  </nav>
</template>

<style scoped>
.on-this-page-link.is-active::before {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  left: -2px;
  width: 2px;
  background-color: var(--gl-tab-selected-indicator-color-default);
  border-radius: 2px;
}
</style>
