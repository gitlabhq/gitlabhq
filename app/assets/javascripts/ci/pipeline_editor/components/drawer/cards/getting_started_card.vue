<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

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
  },
};
</script>
<template>
  <div>
    <h3 class="gl-font-lg gl-mt-0 gl-mb-5">{{ $options.i18n.title }}</h3>
    <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
    <p class="gl-mb-0">
      <gl-sprintf :message="$options.i18n.secondParagraph">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
