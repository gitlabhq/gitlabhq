<script>
import { mapActions, mapState } from 'vuex';
import _ from 'underscore';
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
  },
  mounted() {
    this.getTrace();
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobTrace', 'setDetailJob']),
    scrollDown() {
      if (this.$refs.buildTrace)
        this.$refs.buildTrace.scrollTo(0, this.$refs.buildTrace.scrollHeight);
    },
    scrollUp() {
      if (this.$refs.buildTrace) this.$refs.buildTrace.scrollTo(0, 0);
    },
    scrollBuildLog: _.throttle(function buildLogScrollDebounce() {
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
    <header class="ide-tree-header ide-pipeline-header">
      <button
        class="btn btn-default btn-sm d-flex"
        @click="setDetailJob(null)"
      >
        <icon
          name="chevron-left"
        />
        {{ __('View jobs') }}
      </button>
    </header>
    <div class="top-bar d-flex">
      <job-description
        :job="detailJob"
      />
      <div class="controllers ml-auto">
        <a
          v-tooltip
          :title="__('Show complete raw')"
          data-placement="top"
          data-container="body"
          class="controllers-buttons"
          :href="detailJob.rawPath"
          target="_blank"
        >
          <i
            aria-hidden="true"
            class="fa fa-file-text-o"
          ></i>
        </a>
        <scroll-button
          direction="up"
          :disabled="isScrolledToTop"
          @click="scrollUp"
        />
        <scroll-button
          direction="down"
          :disabled="isScrolledToBottom"
          @click="scrollDown"
        />
      </div>
    </div>
    <pre
      class="build-trace mb-0"
      ref="buildTrace"
      @scroll="scrollBuildLog"
    >
      <code
        class="bash"
        v-html="detailJob.output"
      >
      </code>
      <div
        v-show="detailJob.isLoading"
        class="build-loader-animation"
      >
      </div>
    </pre>
  </div>
</template>
