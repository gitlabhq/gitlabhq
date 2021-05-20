<script>
import { GlEmptyState, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ReleasesEmptyState',
  components: {
    GlEmptyState,
    GlLink,
  },
  inject: {
    documentationPath: {
      default: '',
    },
    illustrationPath: {
      default: '',
    },
  },
  i18n: {
    emptyStateTitle: __('Getting started with releases'),
    emptyStateText: __(
      "Releases are based on Git tags and mark specific points in a project's development history. They can contain information about the type of changes and can also deliver binaries, like compiled versions of your software.",
    ),
    releasesDocumentation: __('Releases documentation'),
    moreInformation: __('More information'),
  },
};
</script>
<template>
  <gl-empty-state :title="$options.i18n.emptyStateTitle" :svg-path="illustrationPath">
    <template #description>
      <span id="releases-description">
        {{ $options.i18n.emptyStateText }}
        <gl-link
          :href="documentationPath"
          :aria-label="$options.i18n.releasesDocumentation"
          target="_blank"
        >
          {{ $options.i18n.moreInformation }}
        </gl-link>
      </span>
    </template>
  </gl-empty-state>
</template>
