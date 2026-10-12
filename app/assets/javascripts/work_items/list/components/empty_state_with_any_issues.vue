<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';

export default {
  name: 'EmptyStateWithAnyIssues',
  components: {
    GlButton,
    GlEmptyState,
  },
  inject: {
    newIssuePath: {
      default: false,
    },
    showNewIssueLink: {
      default: false,
    },
  },
};
</script>

<template>
  <gl-empty-state
    :description="__('To widen your search, change or remove filters above.')"
    :title="__('No results found')"
    illustration-name="empty-search-md"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <slot name="new-issue-button">
        <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
          {{ __('Create issue') }}
        </gl-button>
      </slot>
    </template>
  </gl-empty-state>
</template>
