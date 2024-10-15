<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import EMPTY_SVG from '@gitlab/svgs/dist/illustrations/status/status-nothing-md.svg';
import { translations, environmentsLearnMorePath, environmentsHelpPagePath } from './constants';

export default {
  components: {
    GlSprintf,
    GlLink,
    GlEmptyState,
  },
  translations,
  actionButtonUrl: environmentsHelpPagePath,
  learnMoreHelpPath: environmentsLearnMorePath,
  EMPTY_SVG,
};
</script>
<template>
  <gl-empty-state
    :svg-path="$options.EMPTY_SVG"
    :title="$options.translations.emptyStateTitle"
    :primary-button-text="$options.translations.emptyStatePrimaryButton"
    :primary-button-link="$options.actionButtonUrl"
    class="gl-leading-20"
  >
    <template #description>
      <gl-sprintf :message="$options.translations.emptyStateDescription">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
        <template #link="{ content }">
          <gl-link :href="$options.learnMoreHelpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
