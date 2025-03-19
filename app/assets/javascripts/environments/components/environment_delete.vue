<script>
/**
 * Renders the delete button that allows deleting a stopped environment.
 * Used in the environments table.
 */

import { GlDisclosureDropdownItem, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import setEnvironmentToDelete from '../graphql/mutations/set_environment_to_delete.mutation.graphql';

export default {
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
      isLoading: false,
      item: {
        text: s__('Environments|Delete environment'),
        variant: 'danger',
      },
    };
  },
  methods: {
    onClick() {
      this.$apollo.mutate({
        mutation: setEnvironmentToDelete,
        variables: { environment: this.environment },
      });
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item
    v-gl-modal-directive.delete-environment-modal
    :item="item"
    :loading="isLoading"
    @action="onClick"
  />
</template>
