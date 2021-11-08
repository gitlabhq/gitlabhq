<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import createFlash from '~/flash';
import { __, s__ } from '~/locale';
import runnerDeleteMutation from '~/runner/graphql/runner_delete.mutation.graphql';
import runnerActionsUpdateMutation from '~/runner/graphql/runner_actions_update.mutation.graphql';
import { captureException } from '~/runner/sentry_utils';

const i18n = {
  I18N_EDIT: __('Edit'),
  I18N_PAUSE: __('Pause'),
  I18N_RESUME: __('Resume'),
  I18N_REMOVE: __('Remove'),
  I18N_REMOVE_CONFIRMATION: s__('Runners|Are you sure you want to delete this runner?'),
};

export default {
  name: 'RunnerActionsCell',
  components: {
    GlButton,
    GlButtonGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      updating: false,
      deleting: false,
    };
  },
  computed: {
    isActive() {
      return this.runner.active;
    },
    toggleActiveIcon() {
      return this.isActive ? 'pause' : 'play';
    },
    toggleActiveTitle() {
      if (this.updating) {
        // Prevent a "sticky" tooltip: If this button is disabled,
        // mouseout listeners don't run leaving the tooltip stuck
        return '';
      }
      return this.isActive ? i18n.I18N_PAUSE : i18n.I18N_RESUME;
    },
    deleteTitle() {
      // Prevent a "sticky" tooltip: If element gets removed,
      // mouseout listeners don't run and leaving the tooltip stuck
      return this.deleting ? '' : i18n.I18N_REMOVE;
    },
  },
  methods: {
    async onToggleActive() {
      this.updating = true;
      // TODO In HAML iteration we had a confirmation modal via:
      //   data-confirm="_('Are you sure?')"
      // this may not have to ported, this is an easily reversible operation

      try {
        const toggledActive = !this.runner.active;

        const {
          data: {
            runnerUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerActionsUpdateMutation,
          variables: {
            input: {
              id: this.runner.id,
              active: toggledActive,
            },
          },
        });

        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        }
      } catch (e) {
        this.onError(e);
      } finally {
        this.updating = false;
      }
    },

    async onDelete() {
      // TODO Replace confirmation with gl-modal
      // eslint-disable-next-line no-alert
      if (!window.confirm(i18n.I18N_REMOVE_CONFIRMATION)) {
        return;
      }

      this.deleting = true;
      try {
        const {
          data: {
            runnerDelete: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerDeleteMutation,
          variables: {
            input: {
              id: this.runner.id,
            },
          },
          awaitRefetchQueries: true,
          refetchQueries: ['getRunners', 'getGroupRunners'],
        });
        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        }
      } catch (e) {
        this.onError(e);
      } finally {
        this.deleting = false;
      }
    },

    onError(error) {
      const { message } = error;
      createFlash({ message });

      this.reportToSentry(error);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  i18n,
};
</script>

<template>
  <gl-button-group>
    <!--
      This button appears for administratos: those with
      access to the adminUrl. More advanced permissions policies
      will allow more granular permissions.

      See https://gitlab.com/gitlab-org/gitlab/-/issues/334802
    -->
    <gl-button
      v-if="runner.adminUrl"
      v-gl-tooltip.hover.viewport
      :href="runner.adminUrl"
      :title="$options.i18n.I18N_EDIT"
      :aria-label="$options.i18n.I18N_EDIT"
      icon="pencil"
      data-testid="edit-runner"
    />
    <gl-button
      v-gl-tooltip.hover.viewport
      :title="toggleActiveTitle"
      :aria-label="toggleActiveTitle"
      :icon="toggleActiveIcon"
      :loading="updating"
      data-testid="toggle-active-runner"
      @click="onToggleActive"
    />
    <gl-button
      v-gl-tooltip.hover.viewport
      :title="deleteTitle"
      :aria-label="deleteTitle"
      icon="close"
      :loading="deleting"
      variant="danger"
      data-testid="delete-runner"
      @click="onDelete"
    />
  </gl-button-group>
</template>
