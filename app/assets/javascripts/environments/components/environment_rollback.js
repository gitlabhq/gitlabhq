/* global Flash */
/* eslint-disable no-new */
/**
 * Renders Rollback or Re deploy button in environments table depending
 * of the provided property `isLastDeployment`.
 *
 * Makes a post request when the button is clicked.
 */
import eventHub from '../event_hub';

export default {
  props: {
    retryUrl: {
      type: String,
      default: '',
    },

    isLastDeployment: {
      type: Boolean,
      default: true,
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
      this.isLoading = true;

      $(this.$el).tooltip('destroy');

      this.service.postAction(this.retryUrl)
      .then(() => {
        this.isLoading = false;
        eventHub.$emit('refreshEnvironments');
      })
      .catch(() => {
        this.isLoading = false;
        new Flash('An error occured while making the request.');
      });
    },
  },

  template: `
    <button type="button"
      class="btn"
      @click="onClick"
      :disabled="isLoading">

      <span v-if="isLastDeployment">
        Re-deploy
      </span>
      <span v-else>
        Rollback
      </span>

      <i v-if="isLoading" class="fa fa-spinner fa-spin" aria-hidden="true"></i>
    </button>
  `,
};
