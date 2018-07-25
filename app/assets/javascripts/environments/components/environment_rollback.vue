<script>
/**
 * Renders Rollback or Re deploy button in environments table depending
 * of the provided property `isLastDeployment`.
 *
 * Makes a post request when the button is clicked.
 */
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import eventHub from '../event_hub';
import LoadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  components: {
    Icon,
    LoadingIcon,
  },

  directives: {
    tooltip,
  },

  props: {
    retryUrl: {
      type: String,
      default: '',
    },

    isLastDeployment: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },

  computed: {
    title() {
      return this.isLastDeployment ? s__('Environments|Re-deploy to environment') : s__('Environments|Rollback environment');
    },
  },

  methods: {
    onClick() {
      this.isLoading = true;

      eventHub.$emit('postAction', { endpoint: this.retryUrl });
    },
  },
};
</script>
<template>
  <button
    v-tooltip
    :disabled="isLoading"
    :title="title"
    type="button"
    class="btn d-none d-sm-none d-md-block"
    @click="onClick"
  >

    <icon
      v-if="isLastDeployment"
      name="repeat" />
    <icon
      v-else
      name="redo"/>

    <loading-icon v-if="isLoading" />
  </button>
</template>
