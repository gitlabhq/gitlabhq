<script>
/**
 * Renders a prevent auto-stop button.
 * Used in environments table.
 */
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from '../event_hub';
import cancelAutoStopMutation from '../graphql/mutations/cancel_auto_stop.mutation.graphql';

export default {
  components: {
    GlDisclosureDropdownItem,
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
  data() {
    return {
      item: { text: __('Prevent auto-stopping') },
    };
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
};
</script>
<template>
  <gl-disclosure-dropdown-item :item="item" @action="onPinClick" />
</template>
