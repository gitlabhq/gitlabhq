<script>
import { GlEmptyState } from '@gitlab/ui';
import groupsEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState },
  groupsEmptyStateIllustration,
  computed: {
    title() {
      return s__('GroupsEmptyState|No public or internal groups');
    },
  },
};
</script>

<template>
  <gl-empty-state :title="title" :svg-path="$options.groupsEmptyStateIllustration" />
</template>
