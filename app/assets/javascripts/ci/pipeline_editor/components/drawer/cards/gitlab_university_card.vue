<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { GITLAB_UNIVERSITY_LINK, pipelineEditorTrackingOptions } from '../../../constants';

export default {
  name: 'GitLabUniversityCard',
  GITLAB_UNIVERSITY_LINK,
  GITLAB_UNIVERSITY_URL: 'https://university.gitlab.com/pages/ci-cd-content',
  i18n: {
    title: s__('PipelineEditorTutorial|🎓 Learn CI/CD with GitLab University'),
    body: s__(
      'PipelineEditorTutorial|Learn how to set up and use GitLab CI/CD with guided tutorials, videos, and best practices in %{linkStart}GitLab University%{linkEnd}.',
    ),
  },
  components: {
    GlLink,
    GlSprintf,
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
  <div>
    <h3 class="gl-mb-5 gl-mt-0 gl-text-lg">{{ $options.i18n.title }}</h3>
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
  </div>
</template>
