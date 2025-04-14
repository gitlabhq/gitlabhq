<script>
import { GlTooltipDirective, GlModal } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import deleteEnvironmentMutation from '../graphql/mutations/delete_environment.mutation.graphql';

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
        attributes: { variant: 'danger' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
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
      this.$apollo
        .mutate({
          mutation: deleteEnvironmentMutation,
          variables: { environment: this.environment },
        })
        .then(({ data }) => {
          const [message] = data?.deleteEnvironment?.errors ?? [];
          if (message) {
            createAlert({ message });
          }
        })
        .catch((error) =>
          createAlert({
            message: s__(
              'Environments|An error occurred while deleting the environment. Check if the environment stopped; if not, stop it and try again.',
            ),
            error,
            captureError: true,
          }),
        );
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
