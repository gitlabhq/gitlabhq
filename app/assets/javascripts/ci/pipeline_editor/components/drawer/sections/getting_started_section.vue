<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import PipelineEditorDrawerSection from '../pipeline_editor_drawer_section.vue';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|Get started with GitLab CI/CD'),
    firstParagraph: s__(
      'PipelineEditorTutorial|GitLab CI/CD can automatically build, test, and deploy your application.',
    ),
    secondParagraph: s__(
      'PipelineEditorTutorial|The pipeline stages and jobs are defined in a %{codeStart}.gitlab-ci.yml%{codeEnd} file. You can edit, visualize and validate the syntax in this file by using the pipeline editor. Use the %{codeStart}rules%{codeEnd} keyword to %{linkStart}configure jobs to run in merge requests%{linkEnd}.',
    ),
  },
  addJobsToPipelinesLink: helpPagePath('/ci/pipelines/merge_request_pipelines.html', {
    anchor: 'add-jobs-to-merge-request-pipelines',
  }),
  components: {
    GlSprintf,
    GlLink,
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
        <template #link="{ content }">
          <gl-link :href="$options.addJobsToPipelinesLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </pipeline-editor-drawer-section>
</template>
