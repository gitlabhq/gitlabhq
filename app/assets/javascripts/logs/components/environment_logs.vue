<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlDropdown, GlDropdownItem, GlFormGroup, GlSearchBoxByClick, GlAlert } from '@gitlab/ui';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import { scrollDown } from '~/lib/utils/scroll_utils';
import LogControlButtons from './log_control_buttons.vue';

import { timeRanges, defaultTimeRange } from '~/monitoring/constants';
import { timeRangeFromUrl } from '~/monitoring/utils';

export default {
  components: {
    GlAlert,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlSearchBoxByClick,
    DateTimePicker,
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
  },
  data() {
    return {
      searchQuery: '',
      timeRanges,
      isElasticStackCalloutDismissed: false,
    };
  },
  computed: {
    ...mapState('environmentLogs', ['environments', 'timeRange', 'logs', 'pods']),
    ...mapGetters('environmentLogs', ['trace']),

    timeRangeModel: {
      get() {
        return this.timeRange.current;
      },
      set(val) {
        this.setTimeRange(val);
      },
    },

    showLoader() {
      return this.logs.isLoading || !this.logs.isComplete;
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
  },
  watch: {
    trace(val) {
      this.$nextTick(() => {
        if (val) {
          scrollDown();
        }
        this.$refs.scrollButtons.update();
      });
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
    ]),
  },
};
</script>
<template>
  <div class="build-page-pod-logs mt-3">
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
          :label="s__('Environments|Environment')"
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
            <gl-dropdown-item
              v-for="env in environments.options"
              :key="env.id"
              @click="showEnvironment(env.name)"
            >
              {{ env.name }}
            </gl-dropdown-item>
          </gl-dropdown>
        </gl-form-group>
        <gl-form-group
          id="pods-dropdown-fg"
          :label="s__('Environments|Logs from')"
          label-size="sm"
          label-for="pods-dropdown"
          class="col-3 px-1"
        >
          <gl-dropdown
            id="pods-dropdown"
            :text="pods.current || s__('Environments|No pods to display')"
            :disabled="environments.isLoading"
            class="d-flex gl-h-32 js-pods-dropdown"
            toggle-class="dropdown-menu-toggle"
          >
            <gl-dropdown-item
              v-for="podName in pods.options"
              :key="podName"
              @click="showPodLogs(podName)"
            >
              {{ podName }}
            </gl-dropdown-item>
          </gl-dropdown>
        </gl-form-group>
        <gl-form-group
          id="dates-fg"
          :label="s__('Environments|Show last')"
          label-size="sm"
          label-for="time-window-dropdown"
          class="col-3 px-1"
        >
          <date-time-picker
            ref="dateTimePicker"
            v-model="timeRangeModel"
            class="w-100 gl-h-32"
            :disabled="disableAdvancedControls"
            :options="timeRanges"
          />
        </gl-form-group>
        <gl-form-group
          id="search-fg"
          :label="s__('Environments|Search')"
          label-size="sm"
          label-for="search"
          class="col-3 px-1"
        >
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
      </div>

      <log-control-buttons
        ref="scrollButtons"
        class="controllers align-self-end mb-1"
        @refresh="showPodLogs(pods.current)"
      />
    </div>
    <pre class="build-trace js-log-trace"><code class="bash js-build-output">{{trace}}
      <div v-if="showLoader" class="build-loader-animation js-build-loader-animation">
        <div class="dot"></div>
        <div class="dot"></div>
        <div class="dot"></div>
      </div></code></pre>
  </div>
</template>
