<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import PipelinesCiTemplates from './pipelines_ci_templates.vue';

export default {
  i18n: {
    noCiDescription: s__('Pipelines|This project is not currently set up to run pipelines.'),
  },
  name: 'PipelinesEmptyState',
  components: {
    GlEmptyState,
    PipelinesCiTemplates,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    canSetCi: {
      type: Boolean,
      required: true,
    },
    ciRunnerSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
    anyRunnersAvailable: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>
<template>
  <div>
    <pipelines-ci-templates
      v-if="canSetCi"
      :ci-runner-settings-path="ciRunnerSettingsPath"
      :any-runners-available="anyRunnersAvailable"
    />
    <gl-empty-state
      v-else
      title=""
      :svg-path="emptyStateSvgPath"
      :description="$options.i18n.noCiDescription"
    />
  </div>
</template>
