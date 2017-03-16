/* global Flash */
/* eslint-disable no-new, no-alert */
/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */

export default {
  props: {
    stopUrl: {
      type: String,
      default: '',
    },

    service: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },

  data() {
    return {
      isLoading: false,
    };
  },

  methods: {
    onClick() {
      if (confirm('Are you sure you want to stop this environment?')) {
        this.isLoading = true;

        this.service.postAction(this.retryUrl)
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
          new Flash('An error occured while making the request.', 'alert');
        });
      }
    },
  },

  template: `
    <button type="button"
      class="btn stop-env-link"
      @click="onClick"
      :disabled="isLoading"
      title="Stop Environment">
      <i class="fa fa-stop stop-env-icon" aria-hidden="true"></i>
      <i v-if="isLoading" class="fa fa-spinner fa-spin" aria-hidden="true"></i>
    </button>
  `,
};
