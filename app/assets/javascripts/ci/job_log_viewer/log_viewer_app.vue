<script>
import { s__ } from '~/locale';
import { scrollToElement } from '~/lib/utils/common_utils';
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
          scrollToElement(document.querySelector(hash));
        } catch {
          // selector provider by user is invalid, pass through
        }
      }
    },
  },
};
</script>
<template>
  <div class="build-page gl-m-3">
    <log-viewer-top-bar :has-timestamps="hasTimestamps" />
    <log-viewer :log="log" :loading="loading" />
  </div>
</template>
