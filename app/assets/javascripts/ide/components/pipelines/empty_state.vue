<script>
import { GlEmptyState } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlEmptyState,
  },
  computed: {
    ...mapState(['pipelinesEmptyStateSvgPath']),
    ciHelpPagePath() {
      return helpPagePath('ci/quick_start/_index.md');
    },
  },
  i18n: {
    title: s__('Pipelines|Build with confidence'),
    description: s__(`Pipelines|GitLab CI/CD can automatically build,
      test, and deploy your code. Let GitLab take care of time
      consuming tasks, so you can spend more time creating.`),
    primaryButtonText: s__('Pipelines|Get started with GitLab CI/CD'),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="pipelinesEmptyStateSvgPath"
    :svg-height="150"
    :description="$options.i18n.description"
    :primary-button-text="$options.i18n.primaryButtonText"
    :primary-button-link="ciHelpPagePath"
  />
</template>
