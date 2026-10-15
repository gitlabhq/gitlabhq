<script>
import { GlEmptyState } from '@gitlab/ui';

export default {
  name: 'FilterEmptyState',
  components: {
    GlEmptyState,
  },
};
</script>

<template>
  <gl-empty-state
    :description="__('To widen your search, change or remove filters above.')"
    :title="__('No results found')"
    illustration-name="empty-search-md"
    data-testid="issuable-empty-state"
  />
</template>
