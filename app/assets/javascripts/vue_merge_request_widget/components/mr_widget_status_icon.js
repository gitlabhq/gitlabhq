import ciIcon from '../../vue_shared/components/ci_icon.vue';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  props: {
    status: { type: String, required: true },
    showDisabledButton: { type: Boolean, required: false },
  },
  components: {
    ciIcon,
    loadingIcon,
  },
  computed: {
    statusObj() {
      return {
        group: this.status,
        icon: `status_${this.status}`,
      };
    },
  },
  template: `
    <div class="space-children flex-container-block append-right-10">
      <div v-if="status === 'loading'" class="mr-widget-icon">
        <loading-icon />
      </div>
      <ci-icon v-else :status="statusObj" />
      <button
        v-if="showDisabledButton"
        type="button"
        class="js-disabled-merge-button btn btn-success btn-sm"
        disabled="true">
        Merge
      </button>
    </div>
  `,
};
