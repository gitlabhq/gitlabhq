<script>
import { GlCard } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|💡 Tip: Visualize and validate your pipeline'),
    firstParagraph: s__(
      'PipelineEditorTutorial|Use the Visualize and Lint tabs in the Pipeline Editor to visualize your pipeline and check for any errors or warnings before committing your changes.',
    ),
  },
  components: {
    GlCard,
  },
};
</script>
<template>
  <gl-card>
    <template #default>
      <h4 class="gl-font-lg gl-mt-0">{{ $options.i18n.title }}</h4>
      <p class="gl-mb-0">{{ $options.i18n.firstParagraph }}</p>
    </template>
  </gl-card>
</template>
