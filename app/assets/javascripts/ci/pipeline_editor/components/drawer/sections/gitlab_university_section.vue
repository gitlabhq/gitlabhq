<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { GITLAB_UNIVERSITY_LINK, pipelineEditorTrackingOptions } from '../../../constants';
import PipelineEditorDrawerSection from '../pipeline_editor_drawer_section.vue';

export default {
  name: 'GitLabUniversityCard',
  GITLAB_UNIVERSITY_LINK,
  GITLAB_UNIVERSITY_URL: 'https://university.gitlab.com/pages/ci-cd-content',
  i18n: {
    title: s__('PipelineEditorTutorial|Learn CI/CD with GitLab University'),
    body: s__(
      'PipelineEditorTutorial|Learn how to set up and use GitLab CI/CD with guided tutorials, videos, and best practices in %{linkStart}GitLab University.%{linkEnd}',
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
      this.track(actions.helpDrawerLinks[this.$options.GITLAB_UNIVERSITY_LINK], { label });
    },
  },
};
</script>
<template>
  <pipeline-editor-drawer-section emoji="mortar_board" :title="$options.i18n.title">
    <p class="gl-mb-0">
      <gl-sprintf :message="$options.i18n.body">
        <template #link="{ content }">
          <gl-link
            :href="$options.GITLAB_UNIVERSITY_URL"
            target="_blank"
            @click="trackHelpPageClick"
          >
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
  </pipeline-editor-drawer-section>
</template>
