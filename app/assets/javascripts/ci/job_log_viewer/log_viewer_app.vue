<script>
import { s__ } from '~/locale';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { createAlert } from '~/alert';

import LogViewer from './components/log_viewer.vue';
import LogViewerTopBar from './components/log_viewer_top_bar.vue';

import { fetchLogLines } from './lib/generate_stream';

export default {
  name: 'LogViewerApp',
  components: {
    LogViewerTopBar,
    LogViewer,
  },
  props: {
    rawLogPath: {
      required: true,
      type: String,
      default: null,
    },
  },
  data() {
    return {
      log: [],
      loading: false,
    };
  },
  computed: {
    hasTimestamps() {
      return Boolean(this.log[0]?.timestamp);
    },
  },
  async mounted() {
    performance.mark('LogViewerApp-showLogStart');
    await this.fetchLog();
    performance.mark('LogViewerApp-showLogEnd');

    // scroll once log is loaded and rendered
    this.scrollToLine();
  },
  methods: {
    async fetchLog() {
      this.loading = true;

      try {
        const log = await fetchLogLines(this.rawLogPath);
        Object.freeze(log); // freezing object removes reactivity and lowers memory consumption for large objects

        this.log = log;
      } catch (error) {
        createAlert({
          message: s__('Job|Something went wrong while loading the log.'),
          captureError: true,
          error,
        });
      } finally {
        this.loading = false;
      }
    },
    scrollToLine() {
      const { hash } = window.location;

      if (hash) {
        try {
          const topBarHeight = this.$refs.logViewerTopBar.$el.offsetHeight || 0;
          scrollToElement(document.querySelector(hash), { offset: topBarHeight * -1 });
        } catch {
          // selector provider by user is invalid, pass through
        }
      }
    },
  },
};
</script>
<template>
  <div class="build-page">
    <log-viewer-top-bar ref="logViewerTopBar" :has-timestamps="hasTimestamps" />
    <log-viewer :log="log" :loading="loading" />
  </div>
</template>
