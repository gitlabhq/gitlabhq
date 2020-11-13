<script>
import { GlButton, GlIcon, GlModal, GlModalDirective } from '@gitlab/ui';
import RequestWarning from './request_warning.vue';

export default {
  components: {
    RequestWarning,
    GlButton,
    GlModal,
    GlIcon,
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
      default() {
        return this.metric;
      },
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
    };
  },
  computed: {
    modalId() {
      return `modal-peek-${this.metric}-details`;
    },
    metricDetails() {
      return this.currentRequest.details[this.metric];
    },
    metricDetailsLabel() {
      return this.metricDetails.duration
        ? `${this.metricDetails.duration} / ${this.metricDetails.calls}`
        : this.metricDetails.calls;
    },
    detailsList() {
      return this.metricDetails.details;
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
  },
  methods: {
    toggleBacktrace(toggledIndex) {
      const toggledOpenedIndex = this.openedBacktraces.indexOf(toggledIndex);

      if (toggledOpenedIndex === -1) {
        this.openedBacktraces = [...this.openedBacktraces, toggledIndex];
      } else {
        this.openedBacktraces = this.openedBacktraces.filter(
          openedIndex => openedIndex !== toggledIndex,
        );
      }
    },
    itemHasOpenedBacktrace(toggledIndex) {
      return this.openedBacktraces.find(openedIndex => openedIndex === toggledIndex) >= 0;
    },
  },
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
      {{ metricDetailsLabel }}
    </gl-button>
    <gl-modal :modal-id="modalId" :title="header" size="lg" modal-class="gl-mt-7" scrollable>
      <table class="table">
        <template v-if="detailsList.length">
          <tr v-for="(item, index) in detailsList" :key="index">
            <td>
              <span v-if="item.duration">{{
                sprintf(__('%{duration}ms'), { duration: item.duration })
              }}</span>
            </td>
            <td>
              <div>
                <div
                  v-for="(key, keyIndex) in keys"
                  :key="key"
                  class="break-word"
                  :class="{ 'mb-3 bold': keyIndex == 0 }"
                >
                  {{ item[key] }}
                  <gl-button
                    v-if="keyIndex == 0 && item.backtrace"
                    class="gl-ml-3"
                    data-testid="backtrace-expand-btn"
                    type="button"
                    :aria-label="__('Toggle backtrace')"
                    @click="toggleBacktrace(index)"
                  >
                    <gl-icon :size="12" name="ellipsis_h" />
                  </gl-button>
                </div>
                <pre v-if="itemHasOpenedBacktrace(index)" class="backtrace-row mt-2">{{
                  item.backtrace
                }}</pre>
              </div>
            </td>
          </tr>
        </template>
        <template v-else>
          <tr>
            <td>
              {{ sprintf(__('No %{header} for this request.'), { header: header.toLowerCase() }) }}
            </td>
          </tr>
        </template>
      </table>

      <template #footer>
        <div></div>
      </template>
    </gl-modal>
    {{ title }}
    <request-warning :html-id="htmlId" :warnings="warnings" />
  </div>
</template>
