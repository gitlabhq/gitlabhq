<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlTooltipDirective, GlButton, GlIcon } from '@gitlab/ui';
import { throttle } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __ } from '~/locale';
import JobDescription from './detail/description.vue';
import ScrollButton from './detail/scroll_button.vue';

const scrollPositions = {
  top: 0,
  bottom: 1,
};

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  components: {
    GlButton,
    GlIcon,
    ScrollButton,
    JobDescription,
  },
  data() {
    return {
      scrollPos: scrollPositions.top,
    };
  },
  computed: {
    ...mapState('pipelines', ['detailJob']),
    isScrolledToBottom() {
      return this.scrollPos === scrollPositions.bottom;
    },
    isScrolledToTop() {
      return this.scrollPos === scrollPositions.top;
    },
    jobOutput() {
      return this.detailJob.output || __('No messages were logged');
    },
  },
  mounted() {
    this.getLogs();
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobLogs', 'setDetailJob']),
    scrollDown() {
      if (this.$refs.buildJobLog) {
        this.$refs.buildJobLog.scrollTo(0, this.$refs.buildJobLog.scrollHeight);
      }
    },
    scrollUp() {
      if (this.$refs.buildJobLog) {
        this.$refs.buildJobLog.scrollTo(0, 0);
      }
    },
    scrollBuildLog: throttle(function buildLogScrollDebounce() {
      const { scrollTop } = this.$refs.buildJobLog;
      const { offsetHeight, scrollHeight } = this.$refs.buildJobLog;

      if (scrollTop + offsetHeight === scrollHeight) {
        this.scrollPos = scrollPositions.bottom;
      } else if (scrollTop === 0) {
        this.scrollPos = scrollPositions.top;
      } else {
        this.scrollPos = '';
      }
    }),
    getLogs() {
      return this.fetchJobLogs().then(() => this.scrollDown());
    },
  },
};
</script>

<template>
  <div class="ide-pipeline build-page flex-column flex-fill gl-flex">
    <header class="ide-job-header gl-flex gl-items-center">
      <gl-button category="secondary" icon="chevron-left" size="small" @click="setDetailJob(null)">
        {{ __('View jobs') }}
      </gl-button>
    </header>
    <div class="top-bar border-left-0 mr-3 gl-flex">
      <job-description :job="detailJob" />
      <div class="controllers ml-auto">
        <a
          v-gl-tooltip
          :title="__('Show complete raw log')"
          :href="detailJob.rawPath"
          data-placement="top"
          data-container="body"
          class="controllers-buttons"
          target="_blank"
        >
          <gl-icon name="doc-text" />
        </a>
        <scroll-button :disabled="isScrolledToTop" direction="up" @click="scrollUp" />
        <scroll-button :disabled="isScrolledToBottom" direction="down" @click="scrollDown" />
      </div>
    </div>
    <pre ref="buildJobLog" class="build-log mb-0 mr-3 gl-h-full" @scroll="scrollBuildLog">
      <code
        v-show="!detailJob.isLoading"
        v-safe-html="jobOutput"
        class="bash"
      >
      </code>
      <div
        v-show="detailJob.isLoading"
        class="build-loader-animation"
      >
        <div class="dot"></div>
        <div class="dot"></div>
        <div class="dot"></div>
      </div>
    </pre>
  </div>
</template>
