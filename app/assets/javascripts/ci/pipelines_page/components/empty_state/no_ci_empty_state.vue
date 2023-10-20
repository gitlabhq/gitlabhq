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
  },
};
</script>
<template>
  <pipelines-ci-templates v-if="canSetCi" />
  <gl-empty-state
    v-else
    :svg-path="emptyStateSvgPath"
    :svg-height="null"
    :description="$options.i18n.noCiDescription"
  />
</template>
