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
    this.$nextTick(() => this.handleScrollDown());
  },
  mounted() {
    this.$nextTick(() => this.handleScrollDown());
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
  },
};
</script>
<template>
  <pre class="js-build-trace build-trace qa-build-trace">
    <code
      class="bash"
      v-html="trace"
    >
    </code>

    <div
      v-if="!isComplete"
      class="js-log-animation build-loader-animation"
    >
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </pre>
</template>
