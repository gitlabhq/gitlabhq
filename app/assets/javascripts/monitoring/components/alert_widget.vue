<script>
import { GlBadge, GlLoadingIcon, GlModalDirective, GlIcon, GlTooltip, GlSprintf } from '@gitlab/ui';
import { values, get } from 'lodash';
import createFlash from '~/flash';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import { OPERATORS } from '../constants';
import AlertsService from '../services/alerts_service';
import { alertsValidator, queriesValidator } from '../validators';
import AlertWidgetForm from './alert_widget_form.vue';

export default {
  components: {
    AlertWidgetForm,
    GlBadge,
    GlLoadingIcon,
    GlIcon,
    GlTooltip,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    alertsEndpoint: {
      type: String,
      required: true,
    },
    showLoadingState: {
      type: Boolean,
      required: false,
      default: true,
    },
    // { [alertPath]: { alert_attributes } }. Populated from subsequent API calls.
    // Includes only the metrics/alerts to be managed by this widget.
    alertsToManage: {
      type: Object,
      required: false,
      default: () => ({}),
      validator: alertsValidator,
    },
    // [{ metric+query_attributes }]. Represents queries (and alerts) we know about
    // on intial fetch. Essentially used for reference.
    relevantQueries: {
      type: Array,
      required: true,
      validator: queriesValidator,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      service: null,
      errorMessage: null,
      isLoading: false,
      apiAction: 'create',
    };
  },
  i18n: {
    alertsCountMsg: s__('PrometheusAlerts|%{count} alerts applied'),
    singleFiringMsg: s__('PrometheusAlerts|Firing: %{alert}'),
    multipleFiringMsg: s__('PrometheusAlerts|%{firingCount} firing'),
    firingAlertsTooltip: s__('PrometheusAlerts|Firing: %{alerts}'),
  },
  computed: {
    singleAlertSummary() {
      return {
        message: this.isFiring ? this.$options.i18n.singleFiringMsg : this.thresholds[0],
        alert: this.thresholds[0],
      };
    },
    multipleAlertsSummary() {
      return {
        message: this.isFiring
          ? `${this.$options.i18n.alertsCountMsg}, ${this.$options.i18n.multipleFiringMsg}`
          : this.$options.i18n.alertsCountMsg,
        count: this.thresholds.length,
        firingCount: this.firingAlerts.length,
      };
    },
    shouldShowLoadingIcon() {
      return this.showLoadingState && this.isLoading;
    },
    thresholds() {
      const alertsToManage = Object.keys(this.alertsToManage);
      return alertsToManage.map(this.formatAlertSummary);
    },
    hasAlerts() {
      return Boolean(Object.keys(this.alertsToManage).length);
    },
    hasMultipleAlerts() {
      return this.thresholds.length > 1;
    },
    isFiring() {
      return Boolean(this.firingAlerts.length);
    },
    firingAlerts() {
      return values(this.alertsToManage).filter((alert) =>
        this.passedAlertThreshold(this.getQueryData(alert), alert),
      );
    },
    formattedFiringAlerts() {
      return this.firingAlerts.map((alert) => this.formatAlertSummary(alert.alert_path));
    },
    configuredAlert() {
      return this.hasAlerts ? values(this.alertsToManage)[0].metricId : '';
    },
  },
  created() {
    this.service = new AlertsService({ alertsEndpoint: this.alertsEndpoint });
    this.fetchAlertData();
  },
  methods: {
    fetchAlertData() {
      this.isLoading = true;

      const queriesWithAlerts = this.relevantQueries.filter((query) => query.alert_path);

      return Promise.all(
        queriesWithAlerts.map((query) =>
          this.service
            .readAlert(query.alert_path)
            .then((alertAttributes) => this.setAlert(alertAttributes, query.metricId)),
        ),
      )
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          createFlash({
            message: s__('PrometheusAlerts|Error fetching alert'),
          });
          this.isLoading = false;
        });
    },
    setAlert(alertAttributes, metricId) {
      this.$emit('setAlerts', alertAttributes.alert_path, { ...alertAttributes, metricId });
    },
    removeAlert(alertPath) {
      this.$emit('setAlerts', alertPath, null);
    },
    formatAlertSummary(alertPath) {
      const alert = this.alertsToManage[alertPath];
      const alertQuery = this.relevantQueries.find((query) => query.metricId === alert.metricId);

      return `${alertQuery.label} ${alert.operator} ${alert.threshold}`;
    },
    passedAlertThreshold(data, alert) {
      const { threshold, operator } = alert;

      switch (operator) {
        case OPERATORS.greaterThan:
          return data.some((value) => value > threshold);
        case OPERATORS.lessThan:
          return data.some((value) => value < threshold);
        case OPERATORS.equalTo:
          return data.some((value) => value === threshold);
        default:
          return false;
      }
    },
    getQueryData(alert) {
      const alertQuery = this.relevantQueries.find((query) => query.metricId === alert.metricId);

      return get(alertQuery, 'result[0].values', []).map((value) => get(value, '[1]', null));
    },
    showModal() {
      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    hideModal() {
      this.errorMessage = null;
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    handleSetApiAction(apiAction) {
      this.apiAction = apiAction;
    },
    handleCreate({ operator, threshold, prometheus_metric_id, runbookUrl }) {
      const newAlert = { operator, threshold, prometheus_metric_id, runbookUrl };
      this.isLoading = true;
      this.service
        .createAlert(newAlert)
        .then((alertAttributes) => {
          this.setAlert(alertAttributes, prometheus_metric_id);
          this.isLoading = false;
          this.hideModal();
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error creating alert');
          this.isLoading = false;
        });
    },
    handleUpdate({ alert, operator, threshold, runbookUrl }) {
      const updatedAlert = { operator, threshold, runbookUrl };
      this.isLoading = true;
      this.service
        .updateAlert(alert, updatedAlert)
        .then((alertAttributes) => {
          this.setAlert(alertAttributes, this.alertsToManage[alert].metricId);
          this.isLoading = false;
          this.hideModal();
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
          this.removeAlert(alert);
          this.isLoading = false;
          this.hideModal();
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
  <div class="prometheus-alert-widget dropdown flex-grow-2 overflow-hidden">
    <gl-loading-icon v-if="shouldShowLoadingIcon" :inline="true" size="sm" />
    <span v-else-if="errorMessage" ref="alertErrorMessage" class="alert-error-message">{{
      errorMessage
    }}</span>
    <span
      v-else-if="hasAlerts"
      ref="alertCurrentSetting"
      class="alert-current-setting cursor-pointer d-flex"
      @click="showModal"
    >
      <gl-badge :variant="isFiring ? 'danger' : 'neutral'" class="d-flex-center text-truncate">
        <gl-icon name="warning" :size="16" class="flex-shrink-0" />
        <span class="text-truncate gl-pl-2">
          <gl-sprintf
            :message="
              hasMultipleAlerts ? multipleAlertsSummary.message : singleAlertSummary.message
            "
          >
            <template #alert>
              {{ singleAlertSummary.alert }}
            </template>
            <template #count>
              {{ multipleAlertsSummary.count }}
            </template>
            <template #firingCount>
              {{ multipleAlertsSummary.firingCount }}
            </template>
          </gl-sprintf>
        </span>
      </gl-badge>
      <gl-tooltip v-if="hasMultipleAlerts && isFiring" :target="() => $refs.alertCurrentSetting">
        <gl-sprintf :message="$options.i18n.firingAlertsTooltip">
          <template #alerts>
            <div v-for="alert in formattedFiringAlerts" :key="alert.alert_path">
              {{ alert }}
            </div>
          </template>
        </gl-sprintf>
      </gl-tooltip>
    </span>
    <alert-widget-form
      ref="widgetForm"
      :disabled="isLoading"
      :alerts-to-manage="alertsToManage"
      :relevant-queries="relevantQueries"
      :error-message="errorMessage"
      :configured-alert="configuredAlert"
      :modal-id="modalId"
      @create="handleCreate"
      @update="handleUpdate"
      @delete="handleDelete"
      @cancel="hideModal"
      @setAction="handleSetApiAction"
    />
  </div>
</template>
