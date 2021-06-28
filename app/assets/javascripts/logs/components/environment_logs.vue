<script>
import {
  GlSprintf,
  GlAlert,
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlInfiniteScroll,
} from '@gitlab/ui';
import { throttle } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';

import { timeRangeFromUrl } from '~/monitoring/utils';
import { defaultTimeRange } from '~/vue_shared/constants';
import { formatDate } from '../utils';
import LogAdvancedFilters from './log_advanced_filters.vue';
import LogControlButtons from './log_control_buttons.vue';
import LogSimpleFilters from './log_simple_filters.vue';

export default {
  components: {
    GlSprintf,
    GlAlert,
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlInfiniteScroll,
    LogSimpleFilters,
    LogAdvancedFilters,
    LogControlButtons,
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
    clustersPath: {
      type: String,
      required: true,
    },
  },
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
      return !(
        this.environments.isLoading ||
        this.isElasticStackCalloutDismissed ||
        this.showAdvancedFilters
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
      'showEnvironment',
      'fetchEnvironments',
      'refreshPodLogs',
      'fetchMoreLogsPrepend',
      'dismissRequestEnvironmentsError',
      'dismissInvalidTimeRangeWarning',
      'dismissRequestLogsError',
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
    formatDate,
  },
};
</script>
<template>
  <div class="environment-logs-viewer d-flex flex-column py-3">
    <gl-alert
      v-if="shouldShowElasticStackCallout"
      ref="elasticsearchNotice"
      class="mb-3"
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
    <gl-alert
      v-if="environments.fetchError"
      class="mb-3"
      variant="danger"
      @dismiss="dismissRequestEnvironmentsError"
    >
      {{ s__('Metrics|There was an error fetching the environments data, please try again') }}
    </gl-alert>
    <gl-alert
      v-if="timeRange.invalidWarning"
      class="mb-3"
      variant="warning"
      @dismiss="dismissInvalidTimeRangeWarning"
    >
      {{ s__('Metrics|Invalid time range, please verify.') }}
    </gl-alert>
    <gl-alert
      v-if="logs.fetchError"
      class="mb-3"
      variant="danger"
      @dismiss="dismissRequestLogsError"
    >
      {{ s__('Environments|There was an error fetching the logs. Please try again.') }}
    </gl-alert>

    <div class="top-bar d-md-flex border bg-secondary-50 pt-2 pr-1 pb-0 pl-2">
      <div class="flex-grow-0">
        <gl-dropdown
          id="environments-dropdown"
          :text="environments.current"
          :disabled="environments.isLoading"
          class="gl-mr-3 gl-mb-3 gl-display-flex gl-md-display-block js-environments-dropdown"
        >
          <gl-dropdown-section-header>
            {{ s__('Environments|Environments') }}
          </gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="env in environments.options"
            :key="env.id"
            :is-check-item="true"
            :is-checked="isCurrentEnvironment(env.name)"
            @click="showEnvironment(env.name)"
          >
            {{ env.name }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <log-advanced-filters
        v-if="showAdvancedFilters"
        ref="log-advanced-filters"
        class="d-md-flex flex-grow-1 min-width-0"
        :disabled="environments.isLoading"
      />
      <log-simple-filters
        v-else
        ref="log-simple-filters"
        class="d-md-flex flex-grow-1 min-width-0"
        :disabled="environments.isLoading"
      />

      <log-control-buttons
        ref="scrollButtons"
        class="flex-grow-0 pr-2 mb-2 controllers gl-display-inline-flex"
        :scroll-down-button-disabled="scrollDownButtonDisabled"
        @refresh="refreshPodLogs()"
        @scrollDown="scrollDown"
      />
    </div>

    <gl-infinite-scroll
      ref="infiniteScroll"
      class="log-lines overflow-auto flex-grow-1 min-height-0"
      :fetched-items="logs.lines.length"
      @topReached="topReached"
      @scroll="scroll"
    >
      <template #items>
        <pre
          ref="logTrace"
          class="build-trace"
        ><code class="bash js-build-output"><div v-if="showLoader" class="build-loader-animation js-build-loader-animation">
          <div class="dot"></div>
          <div class="dot"></div>
          <div class="dot"></div>
        </div>{{trace}}
          </code></pre>
      </template>
      <template #default><div></div></template>
    </gl-infinite-scroll>

    <div ref="logFooter" class="py-2 px-3 text-white bg-secondary-900">
      <gl-sprintf :message="s__('Environments|Logs from %{start} to %{end}.')">
        <template #start>{{ formatDate(timeRange.current.start) }}</template>
        <template #end>{{ formatDate(timeRange.current.end) }}</template>
      </gl-sprintf>
      <gl-sprintf
        v-if="!logs.isComplete"
        :message="s__('Environments|Currently showing %{fetched} results.')"
      >
        <template #fetched>{{ logs.lines.length }}</template>
      </gl-sprintf>
      <template v-else> {{ s__('Environments|Currently showing all results.') }}</template>
    </div>
  </div>
</template>
