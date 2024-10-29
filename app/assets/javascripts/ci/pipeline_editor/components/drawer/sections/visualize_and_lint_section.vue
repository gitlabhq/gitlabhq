<script>
import { s__ } from '~/locale';
import PipelineEditorDrawerSection from '../pipeline_editor_drawer_section.vue';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|Tip: Visualize and validate your pipeline'),
    firstParagraph: s__(
      'PipelineEditorTutorial|Use the Visualize and Lint tabs in the pipeline editor to visualize your pipeline and check for any errors or warnings before committing your changes.',
    ),
  },
  components: {
    PipelineEditorDrawerSection,
  },
};
</script>
<template>
  <pipeline-editor-drawer-section emoji="bulb" :title="$options.i18n.title">
    <p class="gl-mb-0">{{ $options.i18n.firstParagraph }}</p>
  </pipeline-editor-drawer-section>
</template>
