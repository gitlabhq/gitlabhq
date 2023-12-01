<!-- eslint-disable vue/multi-word-component-names -->
<script>
// eslint-disable-next-line no-restricted-imports
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
    ...mapState(['jobLogEndpoint', 'jobLog', 'isJobLogComplete']),
    highlightedLines() {
      return this.searchResults.map((result) => result.lineNumber);
    },
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
    isHighlighted({ lineNumber }) {
      return this.highlightedLines.includes(lineNumber);
    },
  },
};
</script>
<template>
  <code class="job-log d-block" data-testid="job-log-content">
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
        :is-highlighted="isHighlighted(section)"
      />
    </template>

    <div v-if="!isJobLogComplete" class="js-log-animation loader-animation pt-3 pl-3">
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </code>
</template>
