<script>
import { debounce } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import {
  GlButton,
  GlIcon,
  GlDeprecatedButton,
  GlDropdown,
  GlDropdownItem,
  GlDropdownHeader,
  GlDropdownDivider,
  GlNewDropdown,
  GlNewDropdownDivider,
  GlNewDropdownItem,
  GlModal,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import { mergeUrlParams, redirectTo } from '~/lib/utils/url_utility';
import invalidUrl from '~/lib/utils/invalid_url';
import Icon from '~/vue_shared/components/icon.vue';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';

import DashboardsDropdown from './dashboards_dropdown.vue';
import RefreshButton from './refresh_button.vue';
import CreateDashboardModal from './create_dashboard_modal.vue';
import DuplicateDashboardModal from './duplicate_dashboard_modal.vue';

import TrackEventDirective from '~/vue_shared/directives/track_event';
import { getAddMetricTrackingOptions, timeRangeToUrl } from '../utils';
import { timeRanges } from '~/vue_shared/constants';
import { timezones } from '../format_date';

export default {
  components: {
    Icon,
    GlButton,
    GlIcon,
    GlDeprecatedButton,
    GlDropdown,
    GlLoadingIcon,
    GlDropdownItem,
    GlDropdownHeader,
    GlDropdownDivider,
    GlNewDropdown,
    GlNewDropdownDivider,
    GlNewDropdownItem,
    GlSearchBoxByType,
    GlModal,
    CustomMetricsFormFields,

    DateTimePicker,
    DashboardsDropdown,
    RefreshButton,
    DuplicateDashboardModal,
    CreateDashboardModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
    TrackEvent: TrackEventDirective,
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
    externalDashboardUrl: {
      type: String,
      required: false,
      default: '',
    },
    hasMetrics: {
      type: Boolean,
      required: false,
      default: true,
    },
    isRearrangingPanels: {
      type: Boolean,
      required: true,
    },
    selectedTimeRange: {
      type: Object,
      required: true,
    },
    addDashboardDocumentationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      formIsValid: null,
    };
  },
  computed: {
    ...mapState('monitoringDashboard', [
      'environmentsLoading',
      'currentEnvironmentName',
      'isUpdatingStarredValue',
      'showEmptyState',
      'dashboardTimezone',
      'projectPath',
      'canAccessOperationsSettings',
      'operationsSettingsPath',
    ]),
    ...mapGetters('monitoringDashboard', ['selectedDashboard', 'filteredEnvironments']),
    isOutOfTheBoxDashboard() {
      return this.selectedDashboard?.out_of_the_box_dashboard;
    },
    shouldShowEnvironmentsDropdownNoMatchedMsg() {
      return !this.environmentsLoading && this.filteredEnvironments.length === 0;
    },
    addingMetricsAvailable() {
      return (
        this.customMetricsAvailable &&
        !this.showEmptyState &&
        // Custom metrics only avaialble on system dashboards because
        // they are stored in the database. This can be improved. See:
        // https://gitlab.com/gitlab-org/gitlab/-/issues/28241
        this.selectedDashboard?.system_dashboard
      );
    },
    showRearrangePanelsBtn() {
      return !this.showEmptyState && this.rearrangePanelsAvailable;
    },
    displayUtc() {
      return this.dashboardTimezone === timezones.UTC;
    },
    shouldShowActionsMenu() {
      return Boolean(this.projectPath);
    },
    shouldShowSettingsButton() {
      return this.canAccessOperationsSettings && this.operationsSettingsPath;
    },
  },
  methods: {
    ...mapActions('monitoringDashboard', ['filterEnvironments', 'toggleStarredValue']),
    selectDashboard(dashboard) {
      const params = {
        dashboard: encodeURIComponent(dashboard.path),
      };

      redirectTo(mergeUrlParams(params, window.location.href));
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
    setFormValidity(isValid) {
      this.formIsValid = isValid;
    },
    hideAddMetricModal() {
      this.$refs.addMetricModal.hide();
    },
    getAddMetricTrackingOptions,
    submitCustomMetricsForm() {
      this.$refs.customMetricsForm.submit();
    },
  },
  modalIds: {
    addMetric: 'addMetric',
    createDashboard: 'createDashboard',
    duplicateDashboard: 'duplicateDashboard',
  },
  i18n: {
    starDashboard: s__('Metrics|Star dashboard'),
    unstarDashboard: s__('Metrics|Unstar dashboard'),
    addMetric: s__('Metrics|Add metric'),
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
        :modal-id="$options.modalIds.duplicateDashboard"
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
        :text="currentEnvironmentName"
      >
        <div class="d-flex flex-column overflow-hidden">
          <gl-dropdown-header class="monitor-environment-dropdown-header text-center">
            {{ __('Environment') }}
          </gl-dropdown-header>
          <gl-dropdown-divider />
          <gl-search-box-by-type
            ref="monitorEnvironmentsDropdownSearch"
            class="m-2"
            @input="debouncedEnvironmentsSearch"
          />
          <gl-loading-icon
            v-if="environmentsLoading"
            ref="monitorEnvironmentsDropdownLoading"
            :inline="true"
          />
          <div v-else class="flex-fill overflow-auto">
            <gl-dropdown-item
              v-for="environment in filteredEnvironments"
              :key="environment.id"
              :active="environment.name === currentEnvironmentName"
              active-class="is-active"
              :href="environment.metrics_path"
              >{{ environment.name }}</gl-dropdown-item
            >
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
      <div v-if="selectedDashboard" class="mb-2 mr-2 d-flex">
        <!--
            wrapper for tooltip as button can be `disabled`
            https://bootstrap-vue.org/docs/components/tooltip#disabled-elements
          -->
        <div
          v-gl-tooltip
          class="flex-grow-1"
          :title="
            selectedDashboard.starred ? $options.i18n.unstarDashboard : $options.i18n.starDashboard
          "
        >
          <gl-deprecated-button
            ref="toggleStarBtn"
            class="w-100"
            :disabled="isUpdatingStarredValue"
            variant="default"
            @click="toggleStarredValue()"
          >
            <gl-icon :name="selectedDashboard.starred ? 'star' : 'star-o'" />
          </gl-deprecated-button>
        </div>
      </div>

      <div v-if="showRearrangePanelsBtn" class="mb-2 mr-2 d-flex">
        <gl-deprecated-button
          :pressed="isRearrangingPanels"
          variant="default"
          class="flex-grow-1 js-rearrange-button"
          @click="toggleRearrangingPanels"
        >
          {{ __('Arrange charts') }}
        </gl-deprecated-button>
      </div>
      <div v-if="addingMetricsAvailable" class="mb-2 mr-2 d-flex d-sm-block">
        <gl-deprecated-button
          ref="addMetricBtn"
          v-gl-modal="$options.modalIds.addMetric"
          variant="outline-success"
          data-qa-selector="add_metric_button"
          class="flex-grow-1"
        >
          {{ $options.i18n.addMetric }}
        </gl-deprecated-button>
        <gl-modal
          ref="addMetricModal"
          :modal-id="$options.modalIds.addMetric"
          :title="$options.i18n.addMetric"
        >
          <form ref="customMetricsForm" :action="customMetricsPath" method="post">
            <custom-metrics-form-fields
              :validate-query-path="validateQueryPath"
              form-operation="post"
              @formValidation="setFormValidity"
            />
          </form>
          <div slot="modal-footer">
            <gl-deprecated-button @click="hideAddMetricModal">
              {{ __('Cancel') }}
            </gl-deprecated-button>
            <gl-deprecated-button
              ref="submitCustomMetricsFormBtn"
              v-track-event="getAddMetricTrackingOptions()"
              :disabled="!formIsValid"
              variant="success"
              @click="submitCustomMetricsForm"
            >
              {{ __('Save changes') }}
            </gl-deprecated-button>
          </div>
        </gl-modal>
      </div>

      <div
        v-if="selectedDashboard && selectedDashboard.can_edit"
        class="mb-2 mr-2 d-flex d-sm-block"
      >
        <gl-deprecated-button
          class="flex-grow-1 js-edit-link"
          :href="selectedDashboard.project_blob_path"
          data-qa-selector="edit_dashboard_button"
        >
          {{ __('Edit dashboard') }}
        </gl-deprecated-button>
      </div>

      <div
        v-if="externalDashboardUrl && externalDashboardUrl.length"
        class="mb-2 mr-2 d-flex d-sm-block"
      >
        <gl-deprecated-button
          class="flex-grow-1 js-external-dashboard-link"
          variant="primary"
          :href="externalDashboardUrl"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ __('View full dashboard') }} <icon name="external-link" />
        </gl-deprecated-button>
      </div>

      <!-- This separator should be displayed only if at least one of the action menu or settings button are displayed  -->
      <span
        v-if="shouldShowActionsMenu || shouldShowSettingsButton"
        aria-hidden="true"
        class="gl-pl-3 border-left gl-mb-3 d-none d-sm-block"
      ></span>

      <div v-if="shouldShowActionsMenu" class="gl-mb-3 gl-mr-3 d-flex d-sm-block">
        <gl-new-dropdown
          v-gl-tooltip
          right
          class="gl-flex-grow-1"
          data-testid="actions-menu"
          :title="s__('Metrics|Create dashboard')"
          :icon="'plus-square'"
        >
          <gl-new-dropdown-item
            v-gl-modal="$options.modalIds.createDashboard"
            data-testid="action-create-dashboard"
            >{{ s__('Metrics|Create new dashboard') }}</gl-new-dropdown-item
          >

          <create-dashboard-modal
            data-testid="create-dashboard-modal"
            :add-dashboard-documentation-path="addDashboardDocumentationPath"
            :modal-id="$options.modalIds.createDashboard"
            :project-path="projectPath"
          />

          <template v-if="isOutOfTheBoxDashboard">
            <gl-new-dropdown-divider />
            <gl-new-dropdown-item
              ref="duplicateDashboardItem"
              v-gl-modal="$options.modalIds.duplicateDashboard"
              data-testid="action-duplicate-dashboard"
            >
              {{ s__('Metrics|Duplicate current dashboard') }}
            </gl-new-dropdown-item>
          </template>
        </gl-new-dropdown>
      </div>

      <div v-if="shouldShowSettingsButton" class="mb-2 mr-2 d-flex d-sm-block">
        <gl-button
          v-gl-tooltip
          data-testid="metrics-settings-button"
          icon="settings"
          :href="operationsSettingsPath"
          :title="s__('Metrics|Metrics Settings')"
        />
      </div>
    </div>
    <duplicate-dashboard-modal
      :default-branch="defaultBranch"
      :modal-id="$options.modalIds.duplicateDashboard"
      @dashboardDuplicated="selectDashboard"
    />
  </div>
</template>
