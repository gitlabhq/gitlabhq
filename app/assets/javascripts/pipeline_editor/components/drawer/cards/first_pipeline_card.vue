<script>
import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|🚀 Run your first pipeline'),
    firstParagraph: s__(
      'PipelineEditorTutorial|This template creates a simple test pipeline. To use it:',
    ),
    listItems: [
      s__(
        'PipelineEditorTutorial|Commit the file to your repository. The pipeline then runs automatically.',
      ),
      s__('PipelineEditorTutorial|The pipeline status is at the top of the page.'),
      s__(
        'PipelineEditorTutorial|Select the pipeline ID to view the full details about your first pipeline run.',
      ),
    ],
    note: s__(
      'PipelineEditorTutorial|If you’re using a self-managed GitLab instance, %{linkStart}make sure your instance has runners available.%{linkEnd}',
    ),
  },
  components: {
    GlCard,
    GlLink,
    GlSprintf,
  },
  inject: ['runnerHelpPagePath'],
};
</script>
<template>
  <gl-card>
    <template #default>
      <h4 class="gl-font-lg gl-mt-0">{{ $options.i18n.title }}</h4>
      <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
      <ol class="gl-mb-3">
        <li v-for="(item, i) in $options.i18n.listItems" :key="`li-${i}`">{{ item }}</li>
      </ol>
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
