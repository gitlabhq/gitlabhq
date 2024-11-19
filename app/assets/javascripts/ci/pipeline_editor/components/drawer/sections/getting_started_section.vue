<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import PipelineEditorDrawerSection from '../pipeline_editor_drawer_section.vue';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|Get started with GitLab CI/CD'),
    firstParagraph: s__(
      'PipelineEditorTutorial|GitLab CI/CD can automatically build, test, and deploy your application.',
    ),
    secondParagraph: s__(
      'PipelineEditorTutorial|The pipeline stages and jobs are defined in a %{codeStart}.gitlab-ci.yml%{codeEnd} file. You can edit, visualize and validate the syntax in this file by using the pipeline editor.',
    ),
  },
  components: {
    GlSprintf,
    PipelineEditorDrawerSection,
  },
};
</script>
<template>
  <pipeline-editor-drawer-section emoji="wave" :title="$options.i18n.title">
    <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
    <p class="gl-mb-0">
      <gl-sprintf :message="$options.i18n.secondParagraph">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
  </pipeline-editor-drawer-section>
</template>
