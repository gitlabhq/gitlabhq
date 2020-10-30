<script>
import { GlEmptyState } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlEmptyState,
  },
  i18n: {
    title: s__('Pipelines|Pipeline Editor'),
    description: s__(
      'Pipelines|We are beginning our work around building the foundation for our dedicated pipeline editor.',
    ),
    primaryButtonText: __('Learn more'),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :primary-button-text="$options.i18n.primaryButtonText"
    primary-button-link="https://about.gitlab.com/direction/verify/pipeline_authoring/"
  />
</template>
