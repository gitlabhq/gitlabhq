<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import EMPTY_VARIABLES_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-variables-md.svg';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  EMPTY_VARIABLES_SVG,
  i18n: {
    title: s__('ManualVariables|There are no manually-specified variables for this pipeline'),
    description: s__(
      'ManualVariables|When you %{helpPageUrlStart}run a pipeline manually%{helpPageUrlEnd}, you can specify additional CI/CD variables to use in that pipeline run.',
    ),
  },
  runPipelineManuallyDocUrl: helpPagePath('ci/pipelines/_index', {
    anchor: 'run-a-pipeline-manually',
  }),
};
</script>

<template>
  <gl-empty-state :svg-path="$options.EMPTY_VARIABLES_SVG" :title="$options.i18n.title">
    <template #description>
      <gl-sprintf :message="$options.i18n.description">
        <template #helpPageUrl="{ content }">
          <gl-link :href="$options.runPipelineManuallyDocUrl" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
