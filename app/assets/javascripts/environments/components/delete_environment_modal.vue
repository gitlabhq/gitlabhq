<script>
import { GlTooltipDirective, GlModal } from '@gitlab/ui';
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
    primaryProps() {
      return {
        text: s__('Environments|Delete environment'),
        attributes: [{ variant: 'danger' }],
      };
    },
    cancelProps() {
      return {
        text: s__('Cancel'),
      };
    },
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
    modalTitle() {
      return sprintf(s__(`Environments|Delete '%{environmentName}'?`), {
        environmentName: this.environment.name,
      });
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
    :modal-id="$options.id"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    :title="modalTitle"
    @primary="onSubmit"
  >
    <p>{{ confirmDeleteMessage }}</p>
  </gl-modal>
</template>
