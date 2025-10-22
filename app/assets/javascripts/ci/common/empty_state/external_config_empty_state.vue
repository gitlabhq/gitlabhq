<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'ExternalConfigEmptyState',
  components: {
    GlEmptyState,
    GlButton,
  },
  i18n: {
    title: s__(
      "ExternalConfigEmptyState|This project's pipeline configuration is located outside this repository",
    ),
    description: s__(
      "ExternalConfigEmptyState|To view or edit the pipeline configuration, check your project's CI/CD settings for the external file location, then navigate to that project or repository.",
    ),
  },
  inject: ['emptyStateIllustrationPath'],
  props: {
    newPipelinePath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :svg-path="emptyStateIllustrationPath"
  >
    <template v-if="newPipelinePath" #actions>
      <gl-button :href="newPipelinePath" variant="confirm">{{
        s__('Pipelines|New pipeline')
      }}</gl-button>
    </template>
  </gl-empty-state>
</template>
