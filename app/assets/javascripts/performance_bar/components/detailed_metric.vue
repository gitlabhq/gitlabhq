<script>
import { GlButton, GlModal, GlModalDirective, GlSegmentedControl } from '@gitlab/ui';

import { s__ } from '~/locale';
import { sortOrders, sortOrderOptions } from '../constants';
import RequestWarning from './request_warning.vue';

export default {
  components: {
    RequestWarning,
    GlButton,
    GlModal,
    GlSegmentedControl,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    currentRequest: {
      type: Object,
      required: true,
    },
    metric: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
    header: {
      type: String,
      required: true,
    },
    keys: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      openedBacktraces: [],
      sortOrder: sortOrders.DURATION,
    };
  },
  computed: {
    modalId() {
      return `modal-peek-${this.metric}-details`;
    },
    metricDetails() {
      return this.currentRequest.details[this.metric];
    },
    metricDetailsSummary() {
      const summary = {};

      if (!this.metricDetails.summaryOptions?.hideTotal) {
        summary[s__('Total')] = this.metricDetails.calls;
      }

      if (!this.metricDetails.summaryOptions?.hideDuration) {
        summary[s__('PerformanceBar|Total duration')] = this.metricDetails.duration;
      }

      return { ...summary, ...(this.metricDetails.summary || {}) };
    },
    metricDetailsLabel() {
      if (this.metricDetails.duration && this.metricDetails.calls) {
        return `${this.metricDetails.duration} / ${this.metricDetails.calls}`;
      } else if (this.metricDetails.calls) {
        return this.metricDetails.calls;
      }

      return '0';
    },
    displaySortOrder() {
      return (
        this.metricDetails.details.length !== 0 &&
        this.metricDetails.details.every((item) => item.start)
      );
    },
    detailsList() {
      return this.metricDetails.details.map((item, index) => ({ ...item, id: index }));
    },
    sortedList() {
      if (this.sortOrder === sortOrders.CHRONOLOGICAL) {
        return this.detailsList.slice().sort(this.sortDetailChronologically);
      }

      return this.detailsList.slice().sort(this.sortDetailByDuration);
    },
    warnings() {
      return this.metricDetails.warnings || [];
    },
    htmlId() {
      if (this.currentRequest) {
        return `performance-bar-warning-${this.currentRequest.id}-${this.metric}`;
      }

      return '';
    },
    actualTitle() {
      return this.title ?? this.metric;
    },
  },
  methods: {
    toggleBacktrace(toggledIndex) {
      const toggledOpenedIndex = this.openedBacktraces.indexOf(toggledIndex);

      if (toggledOpenedIndex === -1) {
        this.openedBacktraces = [...this.openedBacktraces, toggledIndex];
      } else {
        this.openedBacktraces = this.openedBacktraces.filter(
          (openedIndex) => openedIndex !== toggledIndex,
        );
      }
    },
    itemHasOpenedBacktrace(toggledIndex) {
      return this.openedBacktraces.find((openedIndex) => openedIndex === toggledIndex) >= 0;
    },
    changeSortOrder(order) {
      this.sortOrder = order;
    },
    sortDetailByDuration(a, b) {
      return a.duration < b.duration ? 1 : -1;
    },
    sortDetailChronologically(a, b) {
      return a.start < b.start ? -1 : 1;
    },
  },
  sortOrderOptions,
};
</script>
<template>
  <div
    v-if="currentRequest.details && metricDetails"
    :id="`peek-view-${metric}`"
    class="gl-display-flex gl-align-items-center view"
    data-qa-selector="detailed_metric_content"
  >
    <gl-button v-gl-modal="modalId" class="gl-mr-2" type="button" variant="link">
      <span
        class="gl-text-blue-200 gl-font-weight-bold"
        data-testid="performance-bar-details-label"
      >
        {{ metricDetailsLabel }}
      </span>
    </gl-button>
    <gl-modal :modal-id="modalId" :title="header" size="lg" footer-class="d-none" scrollable>
      <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
        <div class="gl-display-flex gl-align-items-center" data-testid="performance-bar-summary">
          <div v-for="(value, name) in metricDetailsSummary" :key="name" class="gl-pr-8">
            <div v-if="value" data-testid="performance-bar-summary-item">
              <div>{{ name }}</div>
              <div class="gl-font-size-h1 gl-font-weight-bold">{{ value }}</div>
            </div>
          </div>
        </div>
        <gl-segmented-control
          v-if="displaySortOrder"
          data-testid="performance-bar-sort-order"
          :options="$options.sortOrderOptions"
          :checked="sortOrder"
          @input="changeSortOrder"
        />
      </div>
      <hr />
      <table class="table gl-table">
        <template v-if="sortedList.length">
          <tr v-for="item in sortedList" :key="item.id">
            <td data-testid="performance-item-duration">
              <span v-if="item.duration">{{
                sprintf(__('%{duration}ms'), { duration: item.duration })
              }}</span>
            </td>
            <td data-testid="performance-item-content">
              <div>
                <div
                  v-for="(key, keyIndex) in keys"
                  :key="key"
                  class="text-break-word"
                  :class="{ 'mb-3 bold': keyIndex == 0 }"
                >
                  {{ item[key] }}
                  <gl-button
                    v-if="keyIndex == 0 && item.backtrace"
                    class="gl-ml-3 button-ellipsis-horizontal"
                    data-testid="backtrace-expand-btn"
                    category="primary"
                    variant="default"
                    icon="ellipsis_h"
                    size="small"
                    :selected="itemHasOpenedBacktrace(item.id)"
                    :aria-label="__('Toggle backtrace')"
                    @click="toggleBacktrace(item.id)"
                  />
                </div>
                <pre v-if="itemHasOpenedBacktrace(item.id)" class="backtrace-row gl-mt-3">{{
                  item.backtrace
                }}</pre>
              </div>
            </td>
          </tr>
        </template>
        <template v-else>
          <tr>
            <td data-testid="performance-bar-empty-detail-notice">
              {{ sprintf(__('No %{header} for this request.'), { header: header.toLowerCase() }) }}
            </td>
          </tr>
        </template>
      </table>

      <template #modal-footer>
        <div></div>
      </template>
    </gl-modal>
    {{ actualTitle }}
    <request-warning :html-id="htmlId" :warnings="warnings" />
  </div>
</template>
