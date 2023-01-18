<script>
import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { translations, codeBlockPlaceholders, environmentsHelpPagePath } from './constants';

export default {
  components: {
    GlSprintf,
    GlEmptyState,
  },
  translations,
  actionButtonUrl: environmentsHelpPagePath,
  placeholders: {
    code: codeBlockPlaceholders,
  },
};
</script>
<template>
  <gl-empty-state
    :title="$options.translations.emptyStateTitle"
    :primary-button-text="$options.translations.emptyStatePrimaryButton"
    :primary-button-link="$options.actionButtonUrl"
  >
    <template #description>
      <gl-sprintf
        :message="$options.translations.emptyStateDescription"
        :placeholders="$options.placeholders.code"
      >
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
