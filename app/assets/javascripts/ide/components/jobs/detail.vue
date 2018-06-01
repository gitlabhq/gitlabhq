<script>
import { mapActions, mapState } from 'vuex';
import _ from 'underscore';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';

const scrollPositions = {
  top: 0,
  bottom: 1,
};

export default {
  directives: {
    tooltip,
  },
  components: {
    CiIcon,
    Icon,
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
    jobId() {
      return `#${this.detailJob.id}`;
    },
  },
  mounted() {
    this.getTrace();
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobTrace', 'setDetailJob']),
    scrollDown() {
      this.$refs.buildTrace.scrollTo(0, this.$refs.buildTrace.scrollHeight);
    },
    scrollUp() {
      this.$refs.buildTrace.scrollTo(0, 0);
    },
    scrollBuildLog: _.throttle(function scrollDebounce() {
      const scrollTop = this.$refs.buildTrace.scrollTop;
      const offsetHeight = this.$refs.buildTrace.offsetHeight;
      const scrollHeight = this.$refs.buildTrace.scrollHeight;

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
      <div class="ide-job-details d-flex align-items-center">
        <ci-icon
          class="append-right-4 d-flex"
          :status="detailJob.status"
          :borderless="true"
          :size="24"
        />
        <span>
          {{ detailJob.name }}
          <a
            :href="detailJob.path"
            target="_blank"
            class="ide-external-link"
          >
            {{ jobId }}
            <icon
              name="external-link"
              :size="12"
            />
          </a>
        </span>
      </div>
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
        <div
          v-tooltip
          class="controllers-buttons"
          data-container="body"
          data-placement="top"
          :title="__('Scroll to top')"
        >
          <button
            class="btn-scroll btn-transparent btn-blank"
            type="button"
            :disabled="isScrolledToTop"
            @click="scrollUp"
          >
            <icon name="scroll_up" />
          </button>
        </div>
        <div
          v-tooltip
          class="controllers-buttons"
          data-container="body"
          data-placement="top"
          :title="__('Scroll to bottom')"
        >
          <button
            class="btn-scroll btn-transparent btn-blank"
            type="button"
            :disabled="isScrolledToBottom"
            @click="scrollDown"
          >
            <icon name="scroll_down" />
          </button>
        </div>
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
