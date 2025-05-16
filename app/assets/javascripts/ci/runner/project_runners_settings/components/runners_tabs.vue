<script>
import { GlTabs } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';
import RunnersTab from './runners_tab.vue';
import RunnerToggleAssignButton from './runner_toggle_assign_button.vue';

export default {
  name: 'RunnersTabs',
  components: {
    GlTabs,
    RunnersTab,
    RunnerToggleAssignButton,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['error'],
  methods: {
    onError(event) {
      this.$emit('error', event);
    },
    onRunnerToggleAssign({ message }) {
      this.$toast?.show(message);

      this.$refs.assignedRunners.refresh();
    },
  },
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
};
</script>
<template>
  <gl-tabs>
    <runners-tab
      ref="assignedRunners"
      :title="s__('Runners|Assigned project runners')"
      :runner-type="$options.PROJECT_TYPE"
      :project-full-path="projectFullPath"
      @error="onError"
    >
      <template #empty>
        {{
          s__(
            'Runners|No project runners found, you can create one by selecting "New project runner".',
          )
        }}
      </template>
      <template #other-runner-actions="{ runner }">
        <runner-toggle-assign-button
          v-if="runner.ownerProject.fullPath !== projectFullPath"
          :project-full-path="projectFullPath"
          :runner="runner"
          :assigns="false"
          @done="onRunnerToggleAssign"
          @error="onError"
        />
      </template>
    </runners-tab>
    <runners-tab
      :title="s__('Runners|Group')"
      :runner-type="$options.GROUP_TYPE"
      :project-full-path="projectFullPath"
      @error="onError"
    >
      <template #empty>
        {{ s__('Runners|No group runners found.') }}
      </template>
    </runners-tab>
    <runners-tab
      :title="s__('Runners|Instance')"
      :runner-type="$options.INSTANCE_TYPE"
      :project-full-path="projectFullPath"
      @error="onError"
    >
      <template #empty>
        {{ s__('Runners|No instance runners found.') }}
      </template>
    </runners-tab>
  </gl-tabs>
</template>
