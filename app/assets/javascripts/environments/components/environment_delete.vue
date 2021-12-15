<script>
/**
 * Renders the delete button that allows deleting a stopped environment.
 * Used in the environments table.
 */

import { GlDropdownItem, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import setEnvironmentToDelete from '../graphql/mutations/set_environment_to_delete.mutation.graphql';

export default {
  components: {
    GlDropdownItem,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    environment: {
      type: Object,
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
      isLoading: false,
    };
  },
  i18n: {
    title: s__('Environments|Delete environment'),
  },
  mounted() {
    if (!this.graphql) {
      eventHub.$on('deleteEnvironment', this.onDeleteEnvironment);
    }
  },
  beforeDestroy() {
    if (!this.graphql) {
      eventHub.$off('deleteEnvironment', this.onDeleteEnvironment);
    }
  },
  methods: {
    onClick() {
      if (this.graphql) {
        this.$apollo.mutate({
          mutation: setEnvironmentToDelete,
          variables: { environment: this.environment },
        });
      } else {
        eventHub.$emit('requestDeleteEnvironment', this.environment);
      }
    },
    onDeleteEnvironment(environment) {
      if (this.environment.id === environment.id) {
        this.isLoading = true;
      }
    },
  },
};
</script>
<template>
  <gl-dropdown-item
    v-gl-modal-directive.delete-environment-modal
    :loading="isLoading"
    variant="danger"
    @click="onClick"
  >
    {{ $options.i18n.title }}
  </gl-dropdown-item>
</template>
