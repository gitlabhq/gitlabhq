<script>
import { GlEmptyState } from '@gitlab/ui';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState },
  i18n: {
    title: s__('GroupsEmptyState|There are no shared projects in this group'),
    description: s__(
      'GroupsEmptyState|You will see here all the projects shared with other groups and projects.',
    ),
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
