<script>
import { mapActions, mapState } from 'vuex';
import { throttle } from 'lodash';
import { __ } from '../../../locale';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import ScrollButton from './detail/scroll_button.vue';
import JobDescription from './detail/description.vue';

const scrollPositions = {
  top: 0,
  bottom: 1,
};

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
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
    this.getTrace();
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobTrace', 'setDetailJob']),
    scrollDown() {
      if (this.$refs.buildTrace) {
        this.$refs.buildTrace.scrollTo(0, this.$refs.buildTrace.scrollHeight);
      }
    },
    scrollUp() {
      if (this.$refs.buildTrace) {
        this.$refs.buildTrace.scrollTo(0, 0);
      }
    },
    scrollBuildLog: throttle(function buildLogScrollDebounce() {
      const { scrollTop } = this.$refs.buildTrace;
      const { offsetHeight, scrollHeight } = this.$refs.buildTrace;

      if (scrollTop + offsetHeight === scrollHeight) {
        this.scrollPos = scrollPositions.bottom;
      } else if (scrollTop === 0) {
        this.scrollPos = scrollPositions.top;
      } else {
        this.scrollPos = '';
      }
    }),
    getTrace() {
      return this.fetchJobTrace().then(() => this.scrollDown());
    },
  },
};
</script>

<template>
  <div class="ide-pipeline build-page d-flex flex-column flex-fill">
    <header class="ide-job-header d-flex align-items-center">
      <button class="btn btn-default btn-sm d-flex" @click="setDetailJob(null)">
        <icon name="chevron-left" /> {{ __('View jobs') }}
      </button>
    </header>
    <div class="top-bar d-flex border-left-0 mr-3">
      <job-description :job="detailJob" />
      <div class="controllers ml-auto">
        <a
          v-tooltip
          :title="__('Show complete raw log')"
          :href="detailJob.rawPath"
          data-placement="top"
          data-container="body"
          class="controllers-buttons"
          target="_blank"
        >
          <i aria-hidden="true" class="fa fa-file-text-o"></i>
        </a>
        <scroll-button :disabled="isScrolledToTop" direction="up" @click="scrollUp" />
        <scroll-button :disabled="isScrolledToBottom" direction="down" @click="scrollDown" />
      </div>
    </div>
    <pre ref="buildTrace" class="build-trace mb-0 h-100 mr-3" @scroll="scrollBuildLog">
      <code
        v-show="!detailJob.isLoading"
        class="bash"
        v-html="jobOutput"
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
