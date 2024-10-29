<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';
import { pipelineEditorTrackingOptions } from '../../../constants';
import PipelineEditorDrawerSection from '../pipeline_editor_drawer_section.vue';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|Run your first pipeline'),
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
    GlLink,
    GlSprintf,
    PipelineEditorDrawerSection,
  },
  mixins: [Tracking.mixin()],
  methods: {
    trackHelpPageClick() {
      const { label, actions } = pipelineEditorTrackingOptions;
      this.track(actions.helpDrawerLinks.runners, { label });
    },
  },
  RUNNER_HELP_URL: `${DOCS_URL}/runner/register/index.html`,
};
</script>
<template>
  <pipeline-editor-drawer-section emoji="rocket" :title="$options.i18n.title">
    <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
    <ol class="gl-mb-3">
      <li v-for="(item, i) in $options.i18n.listItems" :key="`li-${i}`">{{ item }}</li>
    </ol>
    <p class="gl-mb-0">
      <gl-sprintf :message="$options.i18n.note">
        <template #link="{ content }">
          <gl-link :href="$options.RUNNER_HELP_URL" target="_blank" @click="trackHelpPageClick()">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
  </pipeline-editor-drawer-section>
</template>
