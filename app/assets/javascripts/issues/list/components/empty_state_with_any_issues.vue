<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath', 'newIssuePath', 'showNewIssueLink'],
  props: {
    hasSearch: {
      type: Boolean,
      required: true,
    },
    isOpenTab: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <gl-empty-state
    v-if="hasSearch"
    :description="__('To widen your search, change or remove filters above')"
    :title="__('Sorry, your filter produced no results')"
    :svg-path="emptyStateSvgPath"
    :svg-height="150"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
        {{ __('New issue') }}
      </gl-button>
    </template>
  </gl-empty-state>

  <gl-empty-state
    v-else-if="isOpenTab"
    :description="__('To keep this project going, create a new issue')"
    :title="__('There are no open issues')"
    :svg-path="emptyStateSvgPath"
    :svg-height="null"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
        {{ __('New issue') }}
      </gl-button>
    </template>
  </gl-empty-state>

  <gl-empty-state
    v-else
    :title="__('There are no closed issues')"
    :svg-path="emptyStateSvgPath"
    :svg-height="150"
    data-testid="issuable-empty-state"
  />
</template>
