<script>
/**
 * Renders the delete button that allows deleting a stopped environment.
 * Used in the environments table.
 */

import { GlDisclosureDropdownItem, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
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
    graphql: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoading: false,
      item: {
        text: s__('Environments|Delete environment'),
        extraAttrs: {
          variant: 'danger',
          class: '!gl-text-red-500',
        },
      },
    };
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
  <gl-disclosure-dropdown-item
    v-gl-modal-directive.delete-environment-modal
    :item="item"
    :loading="isLoading"
    @action="onClick"
  />
</template>
