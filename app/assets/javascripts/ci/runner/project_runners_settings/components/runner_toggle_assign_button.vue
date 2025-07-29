<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
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
    mutation() {
      if (this.assigns) {
        return runnerAssignToProjectMutation;
      }
      return runnerUnassignFromProjectMutation;
    },
    icon() {
      return this.assigns ? 'link' : 'unlink';
    },
    tooltip() {
      return this.assigns ? s__('Runner|Assign to project') : s__('Runner|Unassign from project');
    },
    doneMessage() {
      const name = formatRunnerName(this.runner);
      return this.assigns
        ? sprintf(s__('Runners|Runner %{name} was assigned to this project.'), { name })
        : sprintf(s__('Runners|Runner %{name} was unassigned from this project.'), { name });
    },
  },
  methods: {
    async onClick() {
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
    :icon="icon"
    :loading="loading"
    @click="onClick"
  />
</template>
