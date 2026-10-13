<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { getScrollingElement } from '~/lib/utils/panels';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import LogLine from './line.vue';
import LogLineHeader from './line_header.vue';

export default {
  name: 'JobLog',
  components: {
    LogLineHeader,
    LogLine,
  },
  inject: ['pagePath'],
  props: {
    searchResults: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: {
    'toggle-collapsible-line': () => true,
  },
  computed: {
    ...mapState(['jobLog', 'jobLogSections', 'isJobLogComplete']),
    highlightedLines() {
      return this.searchResults.map((result) => result.lineNumber);
    },
  },
  mounted() {
    if (window.location.hash) {
      const lineNumber = getLocationHash();

      this.unwatchJobLog = this.$watch(
        'jobLog',
        async () => {
          if (this.jobLog.length) {
            await this.$nextTick();

            const el = document.getElementById(lineNumber);
            // The top bar is sticky and offset from the scroll container top, so
            // offset by its bottom edge (not just its height) to keep the target
            // line from landing behind it.
            const topBar = document.querySelector('.js-job-log-top-bar');
            const scrollContainer = getScrollingElement(el);
            const topBarOffset = topBar
              ? topBar.getBoundingClientRect().bottom - scrollContainer.getBoundingClientRect().top
              : 0;
            scrollToElement(el, { offset: topBarOffset * -1 });

            this.unwatchJobLog();
          }
        },
        { immediate: true },
      );
    }

    this.setupFullScreenListeners();
  },
  methods: {
    ...mapActions(['toggleCollapsibleLine', 'setupFullScreenListeners']),
    handleOnClickCollapsibleLine(section) {
      this.toggleCollapsibleLine(section);
      this.$emit('toggle-collapsible-line');
    },
    isLineVisible(line) {
      const { lineNumber, section } = line;

      if (!section) {
        // lines outside of sections can't be collapsed
        return true;
      }

      return !Object.values(this.jobLogSections).find(
        ({ isClosed, startLineNumber, endLineNumber }) => {
          return isClosed && lineNumber > startLineNumber && lineNumber <= endLineNumber;
        },
      );
    },
    isHighlighted({ lineNumber }) {
      return this.highlightedLines.includes(lineNumber);
    },
  },
};
</script>
<template>
  <code class="job-log gl-block" data-testid="job-log-content">
    <template v-for="line in jobLog">
      <template v-if="isLineVisible(line)">
        <log-line-header
          v-if="line.isHeader"
          :key="line.offset"
          :line="line"
          :path="pagePath"
          :is-closed="jobLogSections[line.section].isClosed"
          :duration="jobLogSections[line.section].duration"
          :hide-duration="jobLogSections[line.section].hideDuration"
          :is-highlighted="isHighlighted(line)"
          @toggle-line="handleOnClickCollapsibleLine(line.section)"
        />
        <log-line
          v-else
          :key="line.offset"
          :line="line"
          :path="pagePath"
          :is-highlighted="isHighlighted(line)"
        />
      </template>
    </template>

    <div v-if="!isJobLogComplete" class="loader-animation gl-pl-5 gl-pt-5">
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </code>
</template>
