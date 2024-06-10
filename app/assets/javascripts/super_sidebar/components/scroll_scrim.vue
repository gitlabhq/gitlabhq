<script>
export default {
  name: 'ScrollScrim',
  data() {
    return {
      topBoundaryVisible: true,
      bottomBoundaryVisible: true,
    };
  },
  computed: {
    scrimClasses() {
      return {
        'top-scrim-visible gl-border-t': !this.topBoundaryVisible,
        'bottom-scrim-visible gl-border-b': !this.bottomBoundaryVisible,
      };
    },
  },
  mounted() {
    this.observeScroll();
  },
  beforeDestroy() {
    this.scrollObserver?.disconnect();
  },

  methods: {
    observeScroll() {
      const root = this.$el;

      const options = {
        rootMargin: '8px',
        root,
        threshold: 1.0,
      };

      this.scrollObserver?.disconnect();

      const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          this[entry.target?.$__visibilityProp] = entry.isIntersecting;
        });
      }, options);

      const topBoundary = this.$refs['top-boundary'];
      const bottomBoundary = this.$refs['bottom-boundary'];

      topBoundary.$__visibilityProp = 'topBoundaryVisible';
      observer.observe(topBoundary);

      bottomBoundary.$__visibilityProp = 'bottomBoundaryVisible';
      observer.observe(bottomBoundary);

      this.scrollObserver = observer;
    },
  },
};
</script>

<template>
  <div class="gl-scroll-scrim gl-overflow-auto" :class="scrimClasses">
    <div class="top-scrim-wrapper">
      <div class="top-scrim"></div>
    </div>
    <div ref="top-boundary"></div>

    <slot></slot>

    <div ref="bottom-boundary"></div>
    <div class="bottom-scrim-wrapper">
      <div class="bottom-scrim"></div>
    </div>
  </div>
</template>
