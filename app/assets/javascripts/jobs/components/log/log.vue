<script>
import { mapState, mapActions } from 'vuex';
import { scrollToElement } from '~/lib/utils/common_utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import CollapsibleLogSection from './collapsible_section.vue';
import LogLine from './line.vue';

export default {
  components: {
    CollapsibleLogSection,
    LogLine,
  },
  props: {
    searchResults: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState([
      'jobLogEndpoint',
      'jobLog',
      'isJobLogComplete',
      'isScrolledToBottomBeforeReceivingJobLog',
    ]),
  },
  updated() {
    this.$nextTick(() => {
      if (!window.location.hash) {
        this.handleScrollDown();
      }
    });
  },
  mounted() {
    if (window.location.hash) {
      const lineNumber = getLocationHash();

      this.unwatchJobLog = this.$watch('jobLog', async () => {
        if (this.jobLog.length) {
          await this.$nextTick();

          const el = document.getElementById(lineNumber);
          scrollToElement(el);
          this.unwatchJobLog();
        }
      });
    }
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
      if (this.isScrolledToBottomBeforeReceivingJobLog) {
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
    <template v-for="(section, index) in jobLog">
      <collapsible-log-section
        v-if="section.isHeader"
        :key="`collapsible-${index}`"
        :section="section"
        :job-log-endpoint="jobLogEndpoint"
        :search-results="searchResults"
        @onClickCollapsibleLine="handleOnClickCollapsibleLine"
      />
      <log-line
        v-else
        :key="section.offset"
        :line="section"
        :path="jobLogEndpoint"
        :search-results="searchResults"
      />
    </template>

    <div v-if="!isJobLogComplete" class="js-log-animation loader-animation pt-3 pl-3">
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </code>
</template>
