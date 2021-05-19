<script>
import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import PipelineVisualReference from '../ui/pipeline_visual_reference.vue';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|🚀 Run your first pipeline'),
    firstParagraph: s__(
      'PipelineEditorTutorial|A typical GitLab pipeline consists of three stages: build, test and deploy. Each stage can have one or more jobs.',
    ),
    secondParagraph: s__(
      'PipelineEditorTutorial|In the example below, %{codeStart}build%{codeEnd} and %{codeStart}deploy%{codeEnd} each contain one job, and %{codeStart}test%{codeEnd} contains two jobs. Your scripts run in jobs like these.',
    ),
    thirdParagraph: s__(
      'PipelineEditorTutorial|You can use %{linkStart}CI/CD examples and templates%{linkEnd} to get your first %{codeStart}.gitlab-ci.yml%{codeEnd} configuration file started. Your first pipeline runs when you commit the changes.',
    ),
    note: s__(
      'PipelineEditorTutorial|If you’re using a self-managed GitLab instance, %{linkStart}make sure your instance has runners available.%{linkEnd}',
    ),
  },
  components: {
    GlCard,
    GlLink,
    GlSprintf,
    PipelineVisualReference,
  },
  inject: ['ciExamplesHelpPagePath', 'runnerHelpPagePath'],
};
</script>
<template>
  <gl-card>
    <template #default>
      <h4 class="gl-font-lg gl-mt-0">{{ $options.i18n.title }}</h4>
      <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
      <p class="gl-mb-3">
        <gl-sprintf :message="$options.i18n.secondParagraph">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>
      <pipeline-visual-reference />
      <p class="gl-my-3">
        <gl-sprintf :message="$options.i18n.thirdParagraph">
          <template #link="{ content }">
            <gl-link :href="ciExamplesHelpPagePath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>
      <p class="gl-mb-0">
        <gl-sprintf :message="$options.i18n.note">
          <template #link="{ content }">
            <gl-link :href="runnerHelpPagePath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-card>
</template>
