<script>
import { GlButton, GlTabs } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import RunnersTab from '~/ci/runner/project_runners_settings/components/runners_tab.vue';
import InstanceRunnersTab from '~/ci/runner/project_runners_settings/components/instance_runners_tab.vue';

export default {
  name: 'ProjectRunnersSettingsApp',
  components: {
    GlButton,
    GlTabs,
    CrudComponent,
    RegistrationDropdown,
    RunnersTab,
    InstanceRunnersTab,
  },
  props: {
    canCreateRunner: {
      type: Boolean,
      required: true,
    },
    allowRegistrationToken: {
      type: Boolean,
      required: true,
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
    newProjectRunnerPath: {
      type: String,
      required: false,
      default: null,
    },
    groupFullPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <crud-component :title="s__('Runners|Runners')" body-class="!gl-m-0">
    <template #actions>
      <gl-button v-if="canCreateRunner" size="small" :href="newProjectRunnerPath">{{
        s__('Runners|New project runner')
      }}</gl-button>
      <registration-dropdown
        size="small"
        type="PROJECT_TYPE"
        :allow-registration-token="allowRegistrationToken"
        :registration-token="registrationToken"
      />
    </template>

    <gl-tabs>
      <runners-tab :title="__('Project')" type="project" :group-full-path="groupFullPath" />
      <runners-tab :title="__('Group')" type="group" :group-full-path="groupFullPath" />
      <instance-runners-tab />
    </gl-tabs>
  </crud-component>
</template>
