<script>
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import AlertWidgetForm from './alert_widget_form.vue';
import AlertsService from '../services/alerts_service';

export default {
  components: {
    Icon,
    AlertWidgetForm,
  },
  props: {
    alertsEndpoint: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    currentAlerts: {
      type: Array,
      require: false,
      default: () => [],
    },
    customMetricId: {
      type: Number,
      require: false,
      default: null,
    },
  },
  data() {
    return {
      service: null,
      errorMessage: null,
      isLoading: false,
      isOpen: false,
      alerts: this.currentAlerts,
      alertData: {},
    };
  },
  computed: {
    alertSummary() {
      const data = this.firstAlertData;
      if (!data) return null;
      return `${this.label} ${data.operator} ${data.threshold}`;
    },
    alertIcon() {
      return this.hasAlerts ? 'notifications' : 'notifications-off';
    },
    alertStatus() {
      return this.hasAlerts
        ? s__('PrometheusAlerts|Alert set')
        : s__('PrometheusAlerts|No alert set');
    },
    dropdownTitle() {
      return this.hasAlerts
        ? s__('PrometheusAlerts|Edit alert')
        : s__('PrometheusAlerts|Add alert');
    },
    hasAlerts() {
      return this.alerts.length > 0;
    },
    firstAlert() {
      return this.hasAlerts ? this.alerts[0] : undefined;
    },
    firstAlertData() {
      return this.hasAlerts ? this.alertData[this.alerts[0]] : undefined;
    },
    formDisabled() {
      return !!(this.errorMessage || this.isLoading);
    },
  },
  watch: {
    isOpen(open) {
      if (open) {
        document.addEventListener('click', this.handleOutsideClick);
      } else {
        document.removeEventListener('click', this.handleOutsideClick);
      }
    },
  },
  created() {
    this.service = new AlertsService({ alertsEndpoint: this.alertsEndpoint });
    this.fetchAlertData();
  },
  beforeDestroy() {
    // clean up external event listeners
    document.removeEventListener('click', this.handleOutsideClick);
  },
  methods: {
    fetchAlertData() {
      this.isLoading = true;
      return Promise.all(
        this.alerts.map(alertPath =>
          this.service
            .readAlert(alertPath)
            .then(alertData => this.$set(this.alertData, alertPath, alertData)),
        ),
      )
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error fetching alert');
          this.isLoading = false;
        });
    },
    handleDropdownToggle() {
      this.isOpen = !this.isOpen;
    },
    handleDropdownClose() {
      this.isOpen = false;
    },
    handleOutsideClick(event) {
      if (!this.$refs.dropdownMenu.contains(event.target)) {
        this.isOpen = false;
      }
    },
    handleCreate({ operator, threshold }) {
      const newAlert = { operator, threshold, prometheus_metric_id: this.customMetricId };
      this.isLoading = true;
      this.service
        .createAlert(newAlert)
        .then(response => {
          const alertPath = response.alert_path;
          this.alerts.unshift(alertPath);
          this.$set(this.alertData, alertPath, newAlert);
          this.isLoading = false;
          this.handleDropdownClose();
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error creating alert');
          this.isLoading = false;
        });
    },
    handleUpdate({ alert, operator, threshold }) {
      const updatedAlert = { operator, threshold };
      this.isLoading = true;
      this.service
        .updateAlert(alert, updatedAlert)
        .then(() => {
          this.$set(this.alertData, alert, updatedAlert);
          this.isLoading = false;
          this.handleDropdownClose();
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error saving alert');
          this.isLoading = false;
        });
    },
    handleDelete({ alert }) {
      this.isLoading = true;
      this.service
        .deleteAlert(alert)
        .then(() => {
          this.$delete(this.alertData, alert);
          this.alerts = this.alerts.filter(alertPath => alert !== alertPath);
          this.isLoading = false;
          this.handleDropdownClose();
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error deleting alert');
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div
    :class="{ show: isOpen }"
    class="prometheus-alert-widget dropdown"
  >
    <span
      v-if="errorMessage"
      class="alert-error-message"
    >
      {{ errorMessage }}
    </span>
    <span
      v-else
      class="alert-current-setting"
    >
      <gl-loading-icon
        v-show="isLoading"
        :inline="true"
      />
      {{ alertSummary }}
    </span>
    <button
      :aria-label="alertStatus"
      class="btn btn-sm alert-dropdown-button"
      type="button"
      @click="handleDropdownToggle"
    >
      <icon
        :name="alertIcon"
        :size="16"
        aria-hidden="true"
      />
      <icon
        :size="16"
        name="arrow-down"
        aria-hidden="true"
        class="chevron"
      />
    </button>
    <div
      ref="dropdownMenu"
      class="dropdown-menu alert-dropdown-menu"
    >
      <div class="dropdown-title">
        <span>{{ dropdownTitle }}</span>
        <button
          class="dropdown-title-button dropdown-menu-close"
          type="button"
          aria-label="Close"
          @click="handleDropdownClose"
        >
          <icon
            :size="12"
            name="close"
            aria-hidden="true"
          />
        </button>
      </div>
      <div class="dropdown-content">
        <alert-widget-form
          ref="widgetForm"
          :disabled="formDisabled"
          :alert="firstAlert"
          :alert-data="firstAlertData"
          @create="handleCreate"
          @update="handleUpdate"
          @delete="handleDelete"
          @cancel="handleDropdownClose"
        />
      </div>
    </div>
  </div>
</template>
