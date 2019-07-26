<script>
import GlModal from '~/vue_shared/components/gl_modal.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlModal,
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
  },
};
</script>
<template>
  <div
    v-if="currentRequest.details"
    :id="`peek-view-${metric}`"
    class="view qa-performance-bar-detailed-metric"
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
              <span>{{ item.duration }}ms</span>
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
  </div>
</template>
