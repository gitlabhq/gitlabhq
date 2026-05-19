<script>
import { GlPopover } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'InlineBlamePopover',
  i18n: {
    title: __('Blame is now in page'),
    body: __(
      'You can now view blame annotations directly on this page by selecting the Blame view.',
    ),
  },
  components: { GlPopover },
  props: {
    targetElement: {
      type: Function,
      required: true,
    },
  },
  emits: ['dismiss'],
  data() {
    return {
      isTargetVisible: true,
      popoverKey: 0,
    };
  },
  computed: {
    resolvedTarget() {
      return this.targetElement();
    },
  },
  mounted() {
    this.bind(this.resolvedTarget);
  },
  beforeDestroy() {
    this.unbind(this.resolvedTarget);
  },
  methods: {
    onTargetClick() {
      this.$emit('dismiss');
    },
    bind(target) {
      if (!target) return;

      target.addEventListener('click', this.onTargetClick);

      if (typeof window.IntersectionObserver === 'function') {
        this.observer = new IntersectionObserver(([entry]) => {
          this.isTargetVisible = entry.isIntersecting;
        });
        this.observer.observe(target);
      }

      // Popper only repositions on scroll/resize events. When a side panel (e.g. Duo Chat)
      // opens and reflows the layout, the blame button moves but Popper isn't notified.
      // Remounting GlPopover via :key forces Popper to recompute against the new position.
      this.resizeObserver = new ResizeObserver(() => {
        clearTimeout(this.resizeTimer);
        this.resizeTimer = setTimeout(() => {
          this.popoverKey += 1;
        }, 150);
      });
      this.resizeObserver.observe(document.querySelector('.content-wrapper') || document.body);
    },
    unbind(target) {
      if (!target) return;

      target.removeEventListener('click', this.onTargetClick);
      this.observer?.disconnect();
      this.observer = null;

      this.resizeObserver?.disconnect();
      this.resizeObserver = null;
      clearTimeout(this.resizeTimer);
    },
  },
};
</script>

<template>
  <gl-popover
    :key="popoverKey"
    :show="isTargetVisible"
    show-close-button
    placement="bottom"
    triggers="manual"
    :target="resolvedTarget"
    :title="$options.i18n.title"
    css-classes="gl-z-200"
    @close-button-clicked="$emit('dismiss')"
  >
    {{ $options.i18n.body }}
  </gl-popover>
</template>
