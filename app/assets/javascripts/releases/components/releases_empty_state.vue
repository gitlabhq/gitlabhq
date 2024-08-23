<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'ReleasesEmptyState',
  components: {
    GlEmptyState,
  },
  inject: ['documentationPath', 'illustrationPath', 'newReleasePath'],
  i18n: {
    emptyStateTitle: s__('Release|Getting started with releases'),
    emptyStateText: s__(
      "Release|Releases are based on Git tags and mark specific points in a project's development history. They can contain information about the type of changes and can also deliver binaries, like compiled versions of your software.",
    ),
    releasesDocumentation: s__('Release|Learn more about releases'),
    moreInformation: s__('Release|More information'),
    newRelease: s__('Release|Create a new release'),
  },
};
</script>
<template>
  <gl-empty-state
    class="gl-mx-auto gl-max-w-limited"
    :title="$options.i18n.emptyStateTitle"
    :description="$options.i18n.emptyStateText"
    :svg-path="illustrationPath"
    :primary-button-link="newReleasePath"
    :primary-button-text="$options.i18n.newRelease"
    :secondary-button-link="documentationPath"
    :secondary-button-text="$options.i18n.releasesDocumentation"
  />
</template>
