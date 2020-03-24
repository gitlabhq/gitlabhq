<script>
import { throttle } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import {
  GlSprintf,
  GlIcon,
  GlAlert,
  GlDropdown,
  GlDropdownHeader,
  GlDropdownItem,
  GlInfiniteScroll,
} from '@gitlab/ui';

import LogSimpleFilters from './log_simple_filters.vue';
import LogAdvancedFilters from './log_advanced_filters.vue';
import LogControlButtons from './log_control_buttons.vue';

import { defaultTimeRange } from '~/vue_shared/constants';
import { timeRangeFromUrl } from '~/monitoring/utils';
import { formatDate } from '../utils';

export default {
  components: {
    GlSprintf,
    GlIcon,
    GlAlert,
    GlDropdown,
    GlDropdownHeader,
    GlDropdownItem,
    GlInfiniteScroll,
    LogSimpleFilters,
    LogAdvancedFilters,
    LogControlButtons,
  },
  filters: {
    formatDate,
  },
  props: {
    environmentName: {
      type: String,
      required: false,
      default: '',
    },
    currentPodName: {
      type: [String, null],
      required: false,
      default: null,
    },
    environmentsPath: {
      type: String,
      required: false,
      default: '',
    },
    clusterApplicationsDocumentationPath: {
      type: String,
      required: true,
    },
  },
  traceHeight: 600,
  data() {
    return {
      isElasticStackCalloutDismissed: false,
      scrollDownButtonDisabled: true,
    };
  },
  computed: {
    ...mapState('environmentLogs', ['environments', 'timeRange', 'logs', 'pods']),
    ...mapGetters('environmentLogs', ['trace', 'showAdvancedFilters']),

    showLoader() {
      return this.logs.isLoading;
    },
    shouldShowElasticStackCallout() {
      return (
        !this.isElasticStackCalloutDismissed &&
        (this.environments.isLoading || !this.showAdvancedFilters)
      );
    },
  },
  mounted() {
    this.setInitData({
      timeRange: timeRangeFromUrl() || defaultTimeRange,
      environmentName: this.environmentName,
      podName: this.currentPodName,
    });

    this.fetchEnvironments(this.environmentsPath);
  },
  methods: {
    ...mapActions('environmentLogs', [
      'setInitData',
      'setSearch',
      'showPodLogs',
      'showEnvironment',
      'fetchEnvironments',
      'fetchMoreLogsPrepend',
    ]),

    isCurrentEnvironment(envName) {
      return envName === this.environments.current;
    },
    topReached() {
      if (!this.logs.isLoading) {
        this.fetchMoreLogsPrepend();
      }
    },
    scrollDown() {
      this.$refs.infiniteScroll.scrollDown();
    },
    scroll: throttle(function scrollThrottled({ target = {} }) {
      const { scrollTop = 0, clientHeight = 0, scrollHeight = 0 } = target;
      this.scrollDownButtonDisabled = scrollTop + clientHeight === scrollHeight;
    }, 200),
  },
};
</script>
<template>
  <div class="environment-logs-viewer mt-3">
    <gl-alert
      v-if="shouldShowElasticStackCallout"
      class="mb-3 js-elasticsearch-alert"
      @dismiss="isElasticStackCalloutDismissed = true"
    >
      {{
        s__(
          'Environments|Install Elastic Stack on your cluster to enable advanced querying capabilities such as full text search.',
        )
      }}
      <a :href="clusterApplicationsDocumentationPath">
        <strong>
          {{ s__('View Documentation') }}
        </strong>
      </a>
    </gl-alert>
    <div class="top-bar d-md-flex border bg-secondary-50 pt-2 pr-1 pb-0 pl-2">
      <div class="flex-grow-0">
        <gl-dropdown
          id="environments-dropdown"
          :text="environments.current"
          :disabled="environments.isLoading"
          class="mb-2 gl-h-32 pr-2 d-flex d-md-block js-environments-dropdown"
        >
          <gl-dropdown-header class="text-center">
            {{ s__('Environments|Select environment') }}
          </gl-dropdown-header>
          <gl-dropdown-item
            v-for="env in environments.options"
            :key="env.id"
            @click="showEnvironment(env.name)"
          >
            <div class="d-flex">
              <gl-icon
                :class="{ invisible: !isCurrentEnvironment(env.name) }"
                name="status_success_borderless"
              />
              <div class="flex-grow-1">{{ env.name }}</div>
            </div>
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <log-advanced-filters
        v-if="showAdvancedFilters"
        ref="log-advanced-filters"
        class="d-md-flex flex-grow-1"
        :disabled="environments.isLoading"
      />
      <log-simple-filters
        v-else
        ref="log-simple-filters"
        class="d-md-flex flex-grow-1"
        :disabled="environments.isLoading"
      />

      <log-control-buttons
        ref="scrollButtons"
        class="flex-grow-0 pr-2 mb-2 controllers"
        :scroll-down-button-disabled="scrollDownButtonDisabled"
        @refresh="showPodLogs(pods.current)"
        @scrollDown="scrollDown"
      />
    </div>

    <gl-infinite-scroll
      ref="infiniteScroll"
      class="log-lines"
      :style="{ height: `${$options.traceHeight}px` }"
      :max-list-height="$options.traceHeight"
      :fetched-items="logs.lines.length"
      @topReached="topReached"
      @scroll="scroll"
    >
      <template #items>
        <pre
          class="build-trace js-log-trace"
        ><code class="bash js-build-output"><div v-if="showLoader" class="build-loader-animation js-build-loader-animation">
          <div class="dot"></div>
          <div class="dot"></div>
          <div class="dot"></div>
        </div>{{trace}}
          </code></pre>
      </template>
      <template #default
        ><div></div
      ></template>
    </gl-infinite-scroll>

    <div ref="logFooter" class="log-footer py-2 px-3">
      <gl-sprintf :message="s__('Environments|Logs from %{start} to %{end}.')">
        <template #start>{{ timeRange.current.start | formatDate }}</template>
        <template #end>{{ timeRange.current.end | formatDate }}</template>
      </gl-sprintf>
      <gl-sprintf
        v-if="!logs.isComplete"
        :message="s__('Environments|Currently showing %{fetched} results.')"
      >
        <template #fetched>{{ logs.lines.length }}</template>
      </gl-sprintf>
      <template v-else>
        {{ s__('Environments|Currently showing all results.') }}</template
      >
    </div>
  </div>
</template>
