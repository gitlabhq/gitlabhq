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
};
</script>
<template>
  <div
    :id="`peek-view-${metric}`"
    class="view"
  >
    <button
      :data-target="`#modal-peek-${metric}-details`"
      class="btn-blank btn-link bold"
      type="button"
      data-toggle="modal"
    >
      <span
        v-if="currentRequest.details"
        class="bold"
      >
        {{ currentRequest.details[metric].duration }}
        /
        {{ currentRequest.details[metric].calls }}
      </span>
    </button>
    <gl-modal
      v-if="currentRequest.details"
      :id="`modal-peek-${metric}-details`"
      :header-title-text="header"
      class="performance-bar-modal"
    >
      <table class="table">
        <tr
          v-for="(item, index) in currentRequest.details[metric][details]"
          :key="index"
        >
          <td><strong>{{ item.duration }}ms</strong></td>
          <td
            v-for="key in keys"
            :key="key"
            class="break-all"
          >
            {{ item[key] }}
          </td>
        </tr>
      </table>

      <div slot="footer">
      </div>
    </gl-modal>
    {{ metric }}
  </div>
</template>
