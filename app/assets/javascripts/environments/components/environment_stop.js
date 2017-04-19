/* global Flash */
/* eslint-disable no-new, no-alert */
/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */
import eventHub from '../event_hub';

export default {
  props: {
    stopUrl: {
      type: String,
      default: '',
    },

    service: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      isLoading: false,
    };
  },

  computed: {
    title() {
      return 'Stop';
    },
  },

  methods: {
    onClick() {
      if (confirm('Are you sure you want to stop this environment?')) {
        this.isLoading = true;

        $(this.$el).tooltip('destroy');

        this.service.postAction(this.retryUrl)
        .then(() => {
          this.isLoading = false;
          eventHub.$emit('refreshEnvironments');
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
      class="btn stop-env-link has-tooltip"
      data-container="body"
      @click="onClick"
      :disabled="isLoading"
      :title="title"
      :aria-label="title">
      <i class="fa fa-stop stop-env-icon" aria-hidden="true"></i>
      <i v-if="isLoading" class="fa fa-spinner fa-spin" aria-hidden="true"></i>
    </button>
  `,
};
