<script>
import { GlTabs } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';
import RunnersTab from './runners_tab.vue';

export default {
  name: 'RunnersTabs',
  components: {
    GlTabs,
    RunnersTab,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['error'],
  methods: {
    onError(error) {
      this.$emit('error', error);
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
      :title="s__('Runners|Project')"
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
