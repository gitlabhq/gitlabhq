<script>
import { GlTooltipDirective } from '@gitlab/ui';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import { s__, sprintf } from '~/locale';
import eventHub from '../event_hub';

export default {
  id: 'delete-environment-modal',
  name: 'DeleteEnvironmentModal',

  components: {
    GlModal,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    environment: {
      type: Object,
      required: true,
    },
  },

  computed: {
    confirmDeleteMessage() {
      return sprintf(
        s__(
          `Environments|Deleting the '%{environmentName}' environment cannot be undone. Do you want to delete it anyway?`,
        ),
        {
          environmentName: this.environment.name,
        },
        false,
      );
    },
  },

  methods: {
    onSubmit() {
      eventHub.$emit('deleteEnvironment', this.environment);
    },
  },
};
</script>

<template>
  <gl-modal
    :id="$options.id"
    :footer-primary-button-text="s__('Environments|Delete environment')"
    footer-primary-button-variant="danger"
    @submit="onSubmit"
  >
    <template #header>
      <h4 class="modal-title d-flex mw-100">
        {{ __('Delete') }}
        <span v-gl-tooltip :title="environment.name" class="text-truncate mx-1 flex-fill">
          {{ environment.name }}?
        </span>
      </h4>
    </template>

    <p>{{ confirmDeleteMessage }}</p>
  </gl-modal>
</template>
