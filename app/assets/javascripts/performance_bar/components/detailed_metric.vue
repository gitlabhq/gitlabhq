<script>
import RequestWarning from './request_warning.vue';

import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    RequestWarning,
    GlModal: DeprecatedModal2,
    Icon,
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
  computed: {
    metricDetails() {
      return this.currentRequest.details[this.metric];
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
};
</script>
<template>
  <div
    v-if="currentRequest.details && metricDetails"
    :id="`peek-view-${metric}`"
    class="view"
    data-qa-selector="detailed_metric_content"
  >
    <button
      :data-target="`#modal-peek-${metric}-details`"
      class="btn-blank btn-link bold"
      type="button"
      data-toggle="modal"
    >
      {{ metricDetails.duration }} / {{ metricDetails.calls }}
    </button>
    <gl-modal
      :id="`modal-peek-${metric}-details`"
      :header-title-text="header"
      modal-size="xl"
      class="performance-bar-modal"
    >
      <table class="table">
        <template v-if="detailsList.length">
          <tr v-for="(item, index) in detailsList" :key="index">
            <td>
              <span>{{ sprintf(__('%{duration}ms'), { duration: item.duration }) }}</span>
            </td>
            <td>
              <div class="js-toggle-container">
                <div
                  v-for="(key, keyIndex) in keys"
                  :key="key"
                  class="break-word"
                  :class="{ 'mb-3 bold': keyIndex == 0 }"
                >
                  {{ item[key] }}
                  <button
                    v-if="keyIndex == 0 && item.backtrace"
                    class="text-expander js-toggle-button"
                    type="button"
                    :aria-label="__('Toggle backtrace')"
                  >
                    <icon :size="12" name="ellipsis_h" />
                  </button>
                </div>
                <pre v-if="item.backtrace" class="backtrace-row js-toggle-content mt-2">{{
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

      <div slot="footer"></div>
    </gl-modal>
    {{ title }}
    <request-warning :html-id="htmlId" :warnings="warnings" />
  </div>
</template>
