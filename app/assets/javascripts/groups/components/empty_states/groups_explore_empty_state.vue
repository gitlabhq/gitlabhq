<script>
import { GlEmptyState } from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  components: { GlEmptyState },
  inject: ['groupsEmptyStateIllustration'],
  i18n: {
    title: __('No public groups'),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="groupsEmptyStateIllustration"
    :svg-height="null"
  />
</template>
