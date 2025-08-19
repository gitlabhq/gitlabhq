<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { captureException } from '../../sentry_utils';
import runnerAssignToProjectMutation from '../../graphql/list/runner_assign_to_project.mutation.graphql';
import runnerUnassignFromProjectMutation from '../../graphql/list/runner_unassign_from_project.mutation.graphql';
import { formatRunnerName } from '../../utils';

export default {
  name: 'RunnerToggleAssignButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    runner: {
      type: Object,
      required: true,
    },
    assigns: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['done', 'error'],
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    runnerName() {
      return formatRunnerName(this.runner);
    },
    mutation() {
      if (this.assigns) {
        return runnerAssignToProjectMutation;
      }
      return runnerUnassignFromProjectMutation;
    },
    icon() {
      return this.assigns ? 'link' : 'unlink';
    },
    variant() {
      return this.assigns ? undefined : 'danger';
    },
    tooltip() {
      return this.assigns ? s__('Runner|Assign to project') : s__('Runner|Unassign from project');
    },
    doneMessage() {
      return this.assigns
        ? sprintf(s__('Runners|Runner %{name} was assigned to this project.'), {
            name: this.runnerName,
          })
        : sprintf(s__('Runners|Runner %{name} was unassigned from this project.'), {
            name: this.runnerName,
          });
    },
  },
  methods: {
    async confirmToggleAssign() {
      if (this.assigns) {
        // Assigning a runner is not destructive, we don't need to confirm
        return true;
      }
      return confirmAction(
        s__(
          'Runner|The runner will be unassigned from this project. Depending on your permissions for this runner, you might not be able to assign it again. Are you sure you want to continue?',
        ),
        {
          title: sprintf(s__('Runners|Unassign runner %{name}?'), { name: this.runnerName }),
          primaryBtnText: s__('Runner|Unassign runner from project'),
          primaryBtnVariant: 'danger',
        },
      );
    },
    async onClick() {
      const confirmed = await this.confirmToggleAssign();
      if (!confirmed) {
        return;
      }

      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: this.mutation,
          variables: {
            runnerId: this.runner.id,
            projectPath: this.projectFullPath,
          },
        });

        const { errors } = data.runnerAssignToProject || data.runnerUnassignFromProject;

        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        }

        this.$emit('done', { message: this.doneMessage });
      } catch (e) {
        this.onError(e);
      } finally {
        this.loading = false;
      }
    },
    onError(error) {
      captureException({ error, component: this.$options.name });

      const message = this.assigns
        ? s__('Runner|Failed to assign runner to project.')
        : s__('Runner|Failed to unassign runner from project.');

      this.$emit('error', { error, message });
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip="tooltip"
    :aria-label="tooltip"
    size="small"
    category="secondary"
    :icon="icon"
    :variant="variant"
    :loading="loading"
    @click="onClick"
  />
</template>
