<script>
import { throttle } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import {
  GlSprintf,
  GlIcon,
  GlAlert,
  GlDropdown,
  GlDropdownHeader,
  GlDropdownDivider,
  GlDropdownItem,
  GlFormGroup,
  GlSearchBoxByClick,
  GlInfiniteScroll,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import LogControlButtons from './log_control_buttons.vue';

import { timeRanges, defaultTimeRange } from '~/vue_shared/constants';
import { timeRangeFromUrl } from '~/monitoring/utils';
import { formatDate } from '../utils';

export default {
  components: {
    GlSprintf,
    GlIcon,
    GlAlert,
    GlDropdown,
    GlDropdownHeader,
    GlDropdownDivider,
    GlDropdownItem,
    GlFormGroup,
    GlSearchBoxByClick,
    GlInfiniteScroll,
    DateTimePicker,
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
      searchQuery: '',
      timeRanges,
      isElasticStackCalloutDismissed: false,
      scrollDownButtonDisabled: true,
    };
  },
  computed: {
    ...mapState('environmentLogs', ['environments', 'timeRange', 'logs', 'pods']),
    ...mapGetters('environmentLogs', ['trace']),

    timeRangeModel: {
      get() {
        return this.timeRange.selected;
      },
      set(val) {
        this.setTimeRange(val);
      },
    },

    showLoader() {
      return this.logs.isLoading;
    },
    advancedFeaturesEnabled() {
      const environment = this.environments.options.find(
        ({ name }) => name === this.environments.current,
      );
      return environment && environment.enable_advanced_logs_querying;
    },
    disableAdvancedControls() {
      return this.environments.isLoading || !this.advancedFeaturesEnabled;
    },
    shouldShowElasticStackCallout() {
      return !this.isElasticStackCalloutDismissed && this.disableAdvancedControls;
    },

    podDropdownText() {
      if (this.pods.current) {
        return this.pods.current;
      } else if (this.advancedFeaturesEnabled) {
        // "All pods" is a valid option when advanced querying is available
        return s__('Environments|All pods');
      }
      return s__('Environments|No pod selected');
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
      'setTimeRange',
      'showPodLogs',
      'showEnvironment',
      'fetchEnvironments',
      'fetchMoreLogsPrepend',
    ]),

    isCurrentEnvironment(envName) {
      return envName === this.environments.current;
    },
    isCurrentPod(podName) {
      return podName === this.pods.current;
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
    <div class="top-bar js-top-bar d-flex">
      <div class="row mx-n1">
        <gl-form-group
          id="environments-dropdown-fg"
          label-size="sm"
          label-for="environments-dropdown"
          class="col-3 px-1"
        >
          <gl-dropdown
            id="environments-dropdown"
            :text="environments.current"
            :disabled="environments.isLoading"
            class="d-flex gl-h-32 js-environments-dropdown"
            toggle-class="dropdown-menu-toggle"
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
        </gl-form-group>

        <gl-form-group
          id="pods-dropdown-fg"
          label-size="sm"
          label-for="pods-dropdown"
          class="col-3 px-1"
        >
          <gl-dropdown
            id="pods-dropdown"
            :text="podDropdownText"
            :disabled="environments.isLoading"
            class="d-flex gl-h-32 js-pods-dropdown"
            toggle-class="dropdown-menu-toggle"
          >
            <gl-dropdown-header class="text-center">
              {{ s__('Environments|Filter by pod') }}
            </gl-dropdown-header>

            <template v-if="advancedFeaturesEnabled">
              <gl-dropdown-item key="all-pods" @click="showPodLogs(null)">
                <div class="d-flex">
                  <gl-icon
                    :class="{ invisible: !isCurrentPod(null) }"
                    name="status_success_borderless"
                  />
                  <div class="flex-grow-1">{{ s__('Environments|All pods') }}</div>
                </div>
              </gl-dropdown-item>
              <gl-dropdown-divider />
            </template>

            <gl-dropdown-item v-if="!pods.options.length" :disabled="true">
              <span class="text-muted">
                {{ s__('Environments|No pods to display') }}
              </span>
            </gl-dropdown-item>
            <gl-dropdown-item
              v-for="podName in pods.options"
              :key="podName"
              class="text-nowrap"
              @click="showPodLogs(podName)"
            >
              <div class="d-flex">
                <gl-icon
                  :class="{ invisible: !isCurrentPod(podName) }"
                  name="status_success_borderless"
                />
                <div class="flex-grow-1">{{ podName }}</div>
              </div>
            </gl-dropdown-item>
          </gl-dropdown>
        </gl-form-group>
        <gl-form-group id="search-fg" label-size="sm" label-for="search" class="col-3 px-1">
          <gl-search-box-by-click
            v-model.trim="searchQuery"
            :disabled="disableAdvancedControls"
            :placeholder="s__('Environments|Search')"
            class="js-logs-search"
            type="search"
            autofocus
            @submit="setSearch(searchQuery)"
          />
        </gl-form-group>

        <gl-form-group
          id="dates-fg"
          label-size="sm"
          label-for="time-window-dropdown"
          class="col-3 px-1"
        >
          <date-time-picker
            ref="dateTimePicker"
            v-model="timeRangeModel"
            class="w-100 gl-h-32"
            right
            :disabled="disableAdvancedControls"
            :options="timeRanges"
          />
        </gl-form-group>
      </div>

      <log-control-buttons
        ref="scrollButtons"
        class="controllers"
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
