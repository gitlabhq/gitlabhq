<script>
import { mapState } from 'vuex';
import _ from 'underscore';
import axios from '../../../lib/utils/axios_utils';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';

const scrollPositions = {
  top: 'top',
  bottom: 'bottom',
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
      loading: true,
    };
  },
  computed: {
    ...mapState('pipelines', ['detailJob']),
    rawUrl() {
      return `${this.detailJob.path}/raw`;
    },
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
  beforeDestroy() {
    clearTimeout(this.timeout);
  },
  methods: {
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
    getTrace(state = null) {
      return axios
        .get(`${this.detailJob.path}/trace`, {
          params: {
            state,
          },
        })
        .then(({ data }) => {
          this.loading = !data.complete;
          this.detailJob.output = data.append ? `${this.detailJob.output}${data.html}` : data.html;

          if (!data.complete) {
            this.timeout = setTimeout(() => this.getTrace(data.state), 4000);
          }
        })
        .then(() => this.$nextTick())
        .then(() => this.scrollDown());
    },
  },
  scrollPositions,
};
</script>

<template>
  <div class="ide-pipeline build-page">
    <header
      class="ide-tree-header ide-pipeline-header"
    >
      <button
        class="btn btn-default btn-sm"
        @click="() => { $store.state.pipelines.detailJob = null; $store.dispatch('setRightPane', 'pipelines-list') }"
      >
        <icon
          name="chevron-left"
        />
        {{ __('View jobs') }}
      </button>
    </header>
    <div
      class="top-bar"
    >
      <div class="ide-job-details float-left">
        <ci-icon
          class="append-right-4"
          :status="detailJob.status"
          :borderless="true"
          :size="24"
        />
        {{ detailJob.name }}
        <a
          :href="detailJob.path"
          target="_blank"
          class="ide-external-link prepend-left-4"
        >
          {{ jobId }}
          <icon
            name="external-link"
            :size="12"
          />
        </a>
      </div>
      <div class="controllers float-right">
        <a
          v-tooltip
          :title="__('Show complete raw')"
          data-placement="top"
          data-container="body"
          class="controllers-buttons"
          :href="rawUrl"
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
            <icon
              name="scroll_up"
            />
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
            <icon
              name="scroll_down"
            />
          </button>
        </div>
      </div>
    </div>
    <pre
      class="build-trace"
      ref="buildTrace"
      @scroll="scrollBuildLog"
    >
      <code
        class="bash"
        v-html="detailJob.output"
      ></code>
      <div
        v-show="loading"
        class="build-loader-animation"
      >
      </div>
    </pre>
  </div>
</template>

<style scoped>
.build-trace-container {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.ide-tree-header .btn {
  display: flex;
}

.ide-job-details {
  display: flex;
}

.ide-job-details .ci-status-icon {
  height: 0;
}

.build-trace {
  margin-bottom: 0;
}
</style>
