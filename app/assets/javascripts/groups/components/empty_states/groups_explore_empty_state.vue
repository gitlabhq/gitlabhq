<script>
import { GlEmptyState } from '@gitlab/ui';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState },
  inject: ['groupsEmptyStateIllustration'],
  computed: {
    title() {
      return window.gon?.dot_com
        ? s__('GroupsEmptyState|No public groups')
        : s__('GroupsEmptyState|No public or internal groups');
    },
  },
};
</script>

<template>
  <gl-empty-state :title="title" :svg-path="groupsEmptyStateIllustration" :svg-height="null" />
</template>
