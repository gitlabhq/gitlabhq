<script>
/**
 * Renders a prevent auto-stop button.
 * Used in environments table.
 */
import { GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from '../event_hub';
import cancelAutoStopMutation from '../graphql/mutations/cancel_auto_stop.mutation.graphql';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    autoStopUrl: {
      type: String,
      required: true,
    },
    graphql: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    onPinClick() {
      if (this.graphql) {
        this.$apollo.mutate({
          mutation: cancelAutoStopMutation,
          variables: { autoStopUrl: this.autoStopUrl },
        });
      } else {
        eventHub.$emit('cancelAutoStop', this.autoStopUrl);
      }
    },
  },
  title: __('Prevent auto-stopping'),
};
</script>
<template>
  <gl-dropdown-item @click="onPinClick">
    {{ $options.title }}
  </gl-dropdown-item>
</template>
