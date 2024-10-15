<script>
import { GlEmptyState } from '@gitlab/ui';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState },
  i18n: {
    title: s__('GroupsEmptyState|There are no inactive projects in this group'),
    description: s__('GroupsEmptyState|Projects that are no longer used are displayed here.'),
  },
  inject: ['emptyProjectsIllustration'],
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :svg-path="emptyProjectsIllustration"
  />
</template>
