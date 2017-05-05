<script>
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
      // eslint-disable-next-line no-alert
      if (confirm('Are you sure you want to stop this environment?')) {
        this.isLoading = true;

        $(this.$el).tooltip('destroy');

        eventHub.$emit('postAction', this.stopUrl);
      }
    },
  },
};
</script>
<template>
  <button
    type="button"
    class="btn stop-env-link has-tooltip"
    data-container="body"
    @click="onClick"
    :disabled="isLoading"
    :title="title"
    :aria-label="title">
    <i
      class="fa fa-stop stop-env-icon"
      aria-hidden="true" />
    <i
      v-if="isLoading"
      class="fa fa-spinner fa-spin"
      aria-hidden="true" />
  </button>
</template>
