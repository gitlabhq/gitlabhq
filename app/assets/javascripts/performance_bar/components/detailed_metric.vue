<script>
import GlModal from '~/vue_shared/components/gl_modal.vue';

export default {
  components: {
    GlModal,
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
    header: {
      type: String,
      required: true,
    },
    details: {
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
      return this.metricDetails[this.details];
    },
  },
};
</script>
<template>
  <div
    :id="`peek-view-${metric}`"
    class="view"
    v-if="currentRequest.details"
  >
    <button
      :data-target="`#modal-peek-${metric}-details`"
      class="btn-blank btn-link bold"
      type="button"
      data-toggle="modal"
    >
      {{ metricDetails.duration }}
      /
      {{ metricDetails.calls }}
    </button>
    <gl-modal
      :id="`modal-peek-${metric}-details`"
      :header-title-text="header"
      class="performance-bar-modal"
    >
      <table
        class="table"
      >
        <template v-if="detailsList.length">
          <tr
            v-for="(item, index) in detailsList"
            :key="index"
          >
            <td><strong>{{ item.duration }}ms</strong></td>
            <td
              v-for="key in keys"
              :key="key"
            >
              {{ item[key] }}
            </td>
          </tr>
        </template>
        <template v-else>
          <tr>
            <td>
              No {{ header.toLowerCase() }} for this request.
            </td>
          </tr>
        </template>
      </table>

      <div slot="footer">
      </div>
    </gl-modal>
    {{ metric }}
  </div>
</template>
