<script>
import { mapState, mapActions } from 'vuex';
import CollpasibleLogSection from './collapsible_section.vue';
import LogLine from './line.vue';

export default {
  components: {
    CollpasibleLogSection,
    LogLine,
  },
  computed: {
    ...mapState([
      'traceEndpoint',
      'trace',
      'isTraceComplete',
      'isScrolledToBottomBeforeReceivingTrace',
    ]),
  },
  updated() {
    this.$nextTick(() => {
      this.handleScrollDown();
    });
  },
  mounted() {
    this.$nextTick(() => {
      this.handleScrollDown();
    });
  },
  methods: {
    ...mapActions(['toggleCollapsibleLine', 'scrollBottom']),
    handleOnClickCollapsibleLine(section) {
      this.toggleCollapsibleLine(section);
    },
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
  <code class="job-log d-block" data-qa-selector="job_log_content">
    <template v-for="(section, index) in trace">
      <collpasible-log-section
        v-if="section.isHeader"
        :key="`collapsible-${index}`"
        :section="section"
        :trace-endpoint="traceEndpoint"
        @onClickCollapsibleLine="handleOnClickCollapsibleLine"
      />
      <log-line v-else :key="section.offset" :line="section" :path="traceEndpoint" />
    </template>

    <div v-if="!isTraceComplete" class="js-log-animation loader-animation pt-3 pl-3">
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </code>
</template>
