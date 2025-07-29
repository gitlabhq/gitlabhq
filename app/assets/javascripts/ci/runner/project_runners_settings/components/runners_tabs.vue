<script>
import { GlTabs } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';
import InstanceRunnersToggle from '~/projects/settings/components/instance_runners_toggle.vue';

import RunnersTab from './runners_tab.vue';
import RunnerToggleAssignButton from './runner_toggle_assign_button.vue';
import GroupRunnersToggle from './group_runners_toggle.vue';
import ProjectRunnersTabEmptyState from './project_runners_tab_empty_state.vue';
import AssignableRunnersTabEmptyState from './assignable_runners_tab_empty_state.vue';
import GroupRunnersTabEmptyState from './group_runners_tab_empty_state.vue';
import InstanceRunnersTabEmptyState from './instance_runners_tab_empty_state.vue';

export default {
  name: 'RunnersTabs',
  components: {
    GlTabs,
    RunnersTab,
    GroupRunnersToggle,
    InstanceRunnersToggle,
    ProjectRunnersTabEmptyState,
    AssignableRunnersTabEmptyState,
    GroupRunnersTabEmptyState,
    InstanceRunnersTabEmptyState,
    RunnerToggleAssignButton,
  },
  inject: {
    canCreateRunnerForGroup: {
      default: false,
    },
    groupRunnersPath: {
      default: null,
    },
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    instanceRunnersEnabled: {
      type: Boolean,
      required: true,
    },
    instanceRunnersDisabledAndUnoverridable: {
      type: Boolean,
      required: true,
    },
    instanceRunnersUpdatePath: {
      type: String,
      required: true,
    },
    instanceRunnersGroupSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
    groupName: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['error'],
  data() {
    return {
      groupRunnersEnabled: null,
      instanceRunnersEnabledModel: this.instanceRunnersEnabled,
    };
  },
  methods: {
    onError(event) {
      this.$emit('error', event);
    },
    onRunnerToggleAssign({ message }) {
      this.$toast?.show(message);

      // Regardless of which tab emitted the event, we refresh the runner list in both.
      this.$refs.assignedRunners.refresh();
      this.$refs.otherAvailableRunners.refresh();
    },
    onGroupRunnersToggled(value) {
      this.groupRunnersEnabled = value;
      this.$refs.groupRunners.refresh();
    },
    onInstanceRunnersToggled(value) {
      this.instanceRunnersEnabledModel = value;
      this.$refs.instanceRunners.refresh();
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
        <project-runners-tab-empty-state />
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
      ref="otherAvailableRunners"
      :title="s__('Runners|Other available project runners')"
      :runner-type="$options.PROJECT_TYPE"
      :project-full-path="projectFullPath"
      use-assignable-query
      @error="onError"
    >
      <template #empty>
        <assignable-runners-tab-empty-state />
      </template>
      <template #other-runner-actions="{ runner }">
        <runner-toggle-assign-button
          :project-full-path="projectFullPath"
          :runner="runner"
          :assigns="true"
          @done="onRunnerToggleAssign"
          @error="onError"
        />
      </template>
    </runners-tab>
    <runners-tab
      ref="groupRunners"
      :title="s__('Runners|Group')"
      :runner-type="$options.GROUP_TYPE"
      :project-full-path="projectFullPath"
      @error="onError"
    >
      <template #description>
        {{ __('These runners are shared across projects in this group.') }}
      </template>
      <template #settings>
        <group-runners-toggle
          :project-full-path="projectFullPath"
          @change="onGroupRunnersToggled"
          @error="onError"
        />
      </template>
      <template #empty>
        <group-runners-tab-empty-state :group-runners-enabled="groupRunnersEnabled" />
      </template>
    </runners-tab>
    <runners-tab
      ref="instanceRunners"
      :title="s__('Runners|Instance')"
      :runner-type="$options.INSTANCE_TYPE"
      :project-full-path="projectFullPath"
      @error="onError"
    >
      <template #settings>
        <instance-runners-toggle
          :is-enabled="instanceRunnersEnabledModel"
          :is-disabled-and-unoverridable="instanceRunnersDisabledAndUnoverridable"
          :update-path="instanceRunnersUpdatePath"
          :group-settings-path="instanceRunnersGroupSettingsPath"
          :group-name="groupName"
          @change="onInstanceRunnersToggled"
        />
      </template>
      <template #empty>
        <instance-runners-tab-empty-state
          :instance-runners-enabled="instanceRunnersEnabledModel"
          :instance-runners-disabled-and-unoverridable="instanceRunnersDisabledAndUnoverridable"
          :group-settings-path="instanceRunnersGroupSettingsPath"
          :group-name="groupName"
        />
      </template>
    </runners-tab>
  </gl-tabs>
</template>
