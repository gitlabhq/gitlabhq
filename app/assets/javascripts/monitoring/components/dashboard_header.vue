<script>
import {
  GlButton,
  GlDropdown,
  GlLoadingIcon,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlModalDirective,
  GlTooltipDirective,
  GlIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import invalidUrl from '~/lib/utils/invalid_url';
import { mergeUrlParams, redirectTo } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';

import { timeRanges } from '~/vue_shared/constants';
import { timezones } from '../format_date';
import { timeRangeToUrl } from '../utils';
import ActionsMenu from './dashboard_actions_menu.vue';
import DashboardsDropdown from './dashboards_dropdown.vue';
import RefreshButton from './refresh_button.vue';

export default {
  i18n: {
    metricsSettings: s__('Metrics|Metrics Settings'),
  },
  components: {
    GlIcon,
    GlButton,
    GlDropdown,
    GlLoadingIcon,
    GlDropdownItem,
    GlDropdownSectionHeader,

    GlSearchBoxByType,

    DateTimePicker,
    DashboardsDropdown,
    RefreshButton,

    ActionsMenu,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    defaultBranch: {
      type: String,
      required: true,
    },
    rearrangePanelsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    customMetricsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    customMetricsPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    validateQueryPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    isRearrangingPanels: {
      type: Boolean,
      required: true,
    },
    selectedTimeRange: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState('monitoringDashboard', [
      'emptyState',
      'environmentsLoading',
      'currentEnvironmentName',
      'dashboardTimezone',
      'projectPath',
      'canAccessOperationsSettings',
      'operationsSettingsPath',
      'currentDashboard',
      'externalDashboardUrl',
    ]),
    ...mapGetters('monitoringDashboard', ['selectedDashboard', 'filteredEnvironments']),
    shouldShowEmptyState() {
      return Boolean(this.emptyState);
    },
    shouldShowEnvironmentsDropdownNoMatchedMsg() {
      return !this.environmentsLoading && this.filteredEnvironments.length === 0;
    },
    addingMetricsAvailable() {
      return (
        this.customMetricsAvailable &&
        !this.shouldShowEmptyState &&
        // Custom metrics only avaialble on system dashboards because
        // they are stored in the database. This can be improved. See:
        // https://gitlab.com/gitlab-org/gitlab/-/issues/28241
        this.selectedDashboard?.out_of_the_box_dashboard
      );
    },
    showRearrangePanelsBtn() {
      return !this.shouldShowEmptyState && this.rearrangePanelsAvailable;
    },
    environmentDropdownText() {
      return this.currentEnvironmentName ?? '';
    },
    displayUtc() {
      return this.dashboardTimezone === timezones.UTC;
    },
    shouldShowSettingsButton() {
      return this.canAccessOperationsSettings && this.operationsSettingsPath;
    },
    isOOTBDashboard() {
      return this.selectedDashboard?.out_of_the_box_dashboard ?? false;
    },
  },
  methods: {
    ...mapActions('monitoringDashboard', ['filterEnvironments']),
    selectDashboard(dashboard) {
      // Once the sidebar See metrics link is updated to the new URL,
      // this sort of hardcoding will not be necessary.
      // https://gitlab.com/gitlab-org/gitlab/-/issues/229277
      const baseURL = `${this.projectPath}/-/metrics`;
      const dashboardPath = encodeURIComponent(
        dashboard.out_of_the_box_dashboard ? dashboard.path : dashboard.display_name,
      );
      redirectTo(`${baseURL}/${dashboardPath}`);
    },
    debouncedEnvironmentsSearch: debounce(function environmentsSearchOnInput(searchTerm) {
      this.filterEnvironments(searchTerm);
    }, 500),
    onDateTimePickerInput(timeRange) {
      redirectTo(timeRangeToUrl(timeRange));
    },
    onDateTimePickerInvalid() {
      this.$emit('dateTimePickerInvalid');
    },

    toggleRearrangingPanels() {
      this.$emit('setRearrangingPanels', !this.isRearrangingPanels);
    },
    getEnvironmentPath(environment) {
      // Once the sidebar See metrics link is updated to the new URL,
      // this sort of hardcoding will not be necessary.
      // https://gitlab.com/gitlab-org/gitlab/-/issues/229277
      const baseURL = `${this.projectPath}/-/metrics`;
      const dashboardPath = encodeURIComponent(this.currentDashboard || '');
      // The environment_metrics_spec.rb requires the URL to not have
      // slashes. Hence, this additional check.
      const url = dashboardPath ? `${baseURL}/${dashboardPath}` : baseURL;
      return mergeUrlParams({ environment }, url);
    },
  },
  timeRanges,
};
</script>

<template>
  <div ref="prometheusGraphsHeader">
    <div class="mb-2 mr-2 d-flex d-sm-block">
      <dashboards-dropdown
        id="monitor-dashboards-dropdown"
        data-qa-selector="dashboards_filter_dropdown"
        class="flex-grow-1"
        toggle-class="dropdown-menu-toggle"
        :default-branch="defaultBranch"
        @selectDashboard="selectDashboard"
      />
    </div>

    <span aria-hidden="true" class="gl-pl-3 border-left gl-mb-3 d-none d-sm-block"></span>

    <div class="mb-2 pr-2 d-flex d-sm-block">
      <gl-dropdown
        id="monitor-environments-dropdown"
        ref="monitorEnvironmentsDropdown"
        class="flex-grow-1"
        data-qa-selector="environments_dropdown"
        toggle-class="dropdown-menu-toggle"
        menu-class="monitor-environment-dropdown-menu"
        :text="environmentDropdownText"
      >
        <div class="d-flex flex-column overflow-hidden">
          <gl-dropdown-section-header>{{ __('Environment') }}</gl-dropdown-section-header>
          <gl-search-box-by-type @input="debouncedEnvironmentsSearch" />

          <gl-loading-icon v-if="environmentsLoading" size="sm" :inline="true" />
          <div v-else class="flex-fill overflow-auto">
            <gl-dropdown-item
              v-for="environment in filteredEnvironments"
              :key="environment.id"
              :is-check-item="true"
              :is-checked="environment.name === currentEnvironmentName"
              :href="getEnvironmentPath(environment.id)"
            >
              {{ environment.name }}
            </gl-dropdown-item>
          </div>
          <div
            v-show="shouldShowEnvironmentsDropdownNoMatchedMsg"
            ref="monitorEnvironmentsDropdownMsg"
            class="text-secondary no-matches-message"
          >
            {{ __('No matching results') }}
          </div>
        </div>
      </gl-dropdown>
    </div>

    <div class="mb-2 pr-2 d-flex d-sm-block">
      <date-time-picker
        ref="dateTimePicker"
        class="flex-grow-1 show-last-dropdown"
        data-qa-selector="range_picker_dropdown"
        :value="selectedTimeRange"
        :options="$options.timeRanges"
        :utc="displayUtc"
        @input="onDateTimePickerInput"
        @invalid="onDateTimePickerInvalid"
      />
    </div>

    <div class="mb-2 pr-2 d-flex d-sm-block">
      <refresh-button />
    </div>

    <div class="flex-grow-1"></div>

    <div class="d-sm-flex">
      <div v-if="showRearrangePanelsBtn" class="mb-2 mr-2 d-flex">
        <gl-button
          :pressed="isRearrangingPanels"
          variant="default"
          class="flex-grow-1 js-rearrange-button"
          @click="toggleRearrangingPanels"
        >
          {{ __('Arrange charts') }}
        </gl-button>
      </div>

      <div
        v-if="externalDashboardUrl && externalDashboardUrl.length"
        class="mb-2 mr-2 d-flex d-sm-block"
      >
        <gl-button
          class="flex-grow-1 js-external-dashboard-link"
          variant="info"
          category="primary"
          :href="externalDashboardUrl"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ __('View full dashboard') }} <gl-icon name="external-link" />
        </gl-button>
      </div>

      <div class="gl-mb-3 gl-mr-3 d-flex d-sm-block">
        <actions-menu
          :adding-metrics-available="addingMetricsAvailable"
          :custom-metrics-path="customMetricsPath"
          :validate-query-path="validateQueryPath"
          :default-branch="defaultBranch"
          :is-ootb-dashboard="isOOTBDashboard"
        />
      </div>

      <template v-if="shouldShowSettingsButton">
        <span aria-hidden="true" class="gl-pl-3 border-left gl-mb-3 d-none d-sm-block"></span>

        <div class="mb-2 mr-2 d-flex d-sm-block">
          <gl-button
            v-gl-tooltip
            data-testid="metrics-settings-button"
            icon="settings"
            :href="operationsSettingsPath"
            :title="$options.i18n.metricsSettings"
            :aria-label="$options.i18n.metricsSettings"
          />
        </div>
      </template>
    </div>
  </div>
</template>
