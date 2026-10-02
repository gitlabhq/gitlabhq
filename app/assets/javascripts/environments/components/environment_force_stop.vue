<script>
/**
 * Renders the dropdown item that force stops an environment that is
 * stuck in the stopping state. Used in the environments table.
 */

import { GlDisclosureDropdownItem, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import setEnvironmentToStopMutation from '../graphql/mutations/set_environment_to_stop.mutation.graphql';

export default {
  name: 'EnvironmentForceStop',
  components: {
    GlDisclosureDropdownItem,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    environment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      item: {
        text: s__('Environments|Force stop environment'),
        variant: 'danger',
      },
    };
  },
  methods: {
    setEnvironmentToStop() {
      this.$apollo.mutate({
        mutation: setEnvironmentToStopMutation,
        variables: { environment: this.environment },
      });
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item
    v-gl-modal-directive="'stop-environment-modal'"
    :item="item"
    @action="setEnvironmentToStop"
  />
</template>
