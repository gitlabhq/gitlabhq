<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('Jobs|Use jobs to automate your tasks'),
    description: s__(
      'Jobs|Jobs are the building blocks of a GitLab CI/CD pipeline. Each job has a specific task, like testing code. To set up jobs in a CI/CD pipeline, add a CI/CD configuration file to your project.',
    ),
    buttonText: s__('Jobs|Create CI/CD configuration file'),
  },
  components: {
    GlEmptyState,
  },
  inject: {
    pipelineEditorPath: {
      default: '',
    },
    emptyStateSvgPath: {
      default: '',
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :svg-path="emptyStateSvgPath"
    :primary-button-link="pipelineEditorPath"
    :primary-button-text="$options.i18n.buttonText"
  />
</template>
