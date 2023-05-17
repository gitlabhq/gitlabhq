<script>
import { GlEmptyState } from '@gitlab/ui';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState },
  i18n: {
    title: s__('GroupsEmptyState|No shared projects.'),
  },
  inject: ['emptyProjectsIllustration'],
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="emptyProjectsIllustration"
    :svg-height="100"
  />
</template>
