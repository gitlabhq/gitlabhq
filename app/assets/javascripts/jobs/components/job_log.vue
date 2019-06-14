<script>
import { mapState, mapActions } from 'vuex';

export default {
  name: 'JobLog',
  props: {
    trace: {
      type: String,
      required: true,
    },
    isComplete: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['isScrolledToBottomBeforeReceivingTrace']),
  },
  updated() {
    this.$nextTick(() => {
      this.handleScrollDown();
      this.handleCollapsibleRows();
    });
  },
  mounted() {
    this.$nextTick(() => {
      this.handleScrollDown();
      this.handleCollapsibleRows();
    });
  },
  destroyed() {
    this.removeEventListener();
  },
  methods: {
    ...mapActions(['scrollBottom']),
    /**
     * The job log is sent in HTML, which means we need to use `v-html` to render it
     * Using the updated hook with $nextTick is not enough to wait for the DOM to be updated
     * in this case because it runs before `v-html` has finished running, since there's no
     * Vue binding.
     * In order to scroll the page down after `v-html` has finished, we need to use setTimeout
     */
    handleScrollDown() {
      if (this.isScrolledToBottomBeforeReceivingTrace) {
        setTimeout(() => {
          this.scrollBottom();
        }, 0);
      }
    },
    removeEventListener() {
      this.$el
        .querySelectorAll('.js-section-start')
        .forEach(el => el.removeEventListener('click', this.handleSectionClick));
    },
    /**
     * The collapsible rows are sent in HTML from the backend
     * We need tos add a onclick handler for the divs that match `.js-section-start`
     *
     */
    handleCollapsibleRows() {
      this.$el
        .querySelectorAll('.js-section-start')
        .forEach(el => el.addEventListener('click', this.handleSectionClick));
    },
    /**
     * On click, we toggle the hidden class of
     * all the rows that match the `data-section` selector
     */
    handleSectionClick(evt) {
      const clickedArrow = evt.currentTarget;
      // toggle the arrow class
      clickedArrow.classList.toggle('fa-caret-right');
      clickedArrow.classList.toggle('fa-caret-down');

      const { section } = clickedArrow.dataset;
      const sibilings = this.$el.querySelectorAll(`.js-s-${section}:not(.js-section-header)`);

      sibilings.forEach(row => row.classList.toggle('hidden'));
    },
  },
};
</script>
<template>
  <pre class="js-build-trace build-trace qa-build-trace">
    <code class="bash" v-html="trace">
    </code>

    <div v-if="!isComplete" class="js-log-animation build-loader-animation">
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </pre>
</template>
