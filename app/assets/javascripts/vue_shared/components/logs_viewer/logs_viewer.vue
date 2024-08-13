<script>
import { isNumber } from 'lodash';
import throttle from 'lodash/throttle';
import { scrollToElement } from '~/lib/utils/common_utils';
import LogLine from './log_line.vue';
import LogsTopBar from './logs_top_bar.vue';

export default {
  components: {
    LogLine,
    LogsTopBar,
  },
  props: {
    logLines: {
      /* Array<{
            content: Array<{text: string}>
            lineNumber: Number
        }> */
      type: Array,
      required: true,
      validator: (fields) =>
        fields.length && fields.every(({ lineNumber }) => isNumber(lineNumber)),
    },
    highlightedLine: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isFullScreen: false,
      isFollowing: true,
    };
  },
  created() {
    this.followLogs();
  },
  mounted() {
    document.addEventListener('fullscreenchange', this.onFullScreenChange);
  },
  beforeDestroy() {
    document.removeEventListener('fullscreenchange', this.onFullScreenChange);
  },
  methods: {
    followLogs() {
      const unwatch = this.$watch(
        'logLines',
        throttle(async (newLogLines) => {
          if (!newLogLines?.length || !this.isFollowing) {
            return;
          }

          const lineIdToScroll =
            this.highlightedLine || `${newLogLines[newLogLines.length - 1].lineId}`;
          await this.$nextTick();

          const el = document.getElementById(lineIdToScroll);
          if (el) {
            scrollToElement(el, { duration: 0 });
            if (!this.isFollowing) {
              unwatch();
            }
          }
        }, 180),
      );
    },
    isLineHighlighted(line, hash) {
      const lineToMatch = line.lineId;
      return hash === lineToMatch;
    },
    onFullScreenChange() {
      this.isFullScreen = Boolean(document.fullscreenElement);
    },
    toggleFullScreen() {
      const el = document.querySelector('.log-view-container');
      if (this.isFullScreen) {
        document.exitFullscreen();
        return;
      }

      if (el.requestFullscreen) {
        el.requestFullscreen();
      }
    },
    scrollToLine(lineId) {
      const el = document.getElementById(lineId);
      if (el) {
        scrollToElement(el);
      }
    },
    onScrollToTop() {
      this.isFollowing = false;
      this.scrollToLine(this.logLines[0].lineId);
    },
    onScrollToBottom() {
      if (this.isFollowing) {
        this.isFollowing = false;
      } else {
        this.isFollowing = true;
        this.scrollToLine(this.logLines[this.logLines.length - 1].lineId);
        this.followLogs();
      }
    },
  },
};
</script>
<template>
  <div class="log-view-container" :class="{ 'gl-overflow-scroll': isFullScreen }">
    <logs-top-bar
      :is-full-screen="isFullScreen"
      :is-following="isFollowing"
      @toggleFullScreen="toggleFullScreen"
      @scrollToTop="onScrollToTop"
      @scrollToBottom="onScrollToBottom"
      ><slot name="header-details"></slot>
    </logs-top-bar>
    <code class="gl-block gl-bg-black gl-pt-3 gl-text-base">
      <log-line
        v-for="logLine in logLines"
        :key="logLine.lineId"
        :line="logLine"
        :is-highlighted="isLineHighlighted(logLine, highlightedLine)"
      />
    </code>
  </div>
</template>
