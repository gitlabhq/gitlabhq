<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { i18n } from '../constants';

export default {
  i18n,
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
    :description="$options.i18n.noSearchResultsDescription"
    :title="$options.i18n.noSearchResultsTitle"
    :svg-path="emptyStateSvgPath"
    :svg-height="150"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
        {{ $options.i18n.newIssueLabel }}
      </gl-button>
    </template>
  </gl-empty-state>

  <gl-empty-state
    v-else-if="isOpenTab"
    :description="$options.i18n.noOpenIssuesDescription"
    :title="$options.i18n.noOpenIssuesTitle"
    :svg-path="emptyStateSvgPath"
    :svg-height="null"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
        {{ $options.i18n.newIssueLabel }}
      </gl-button>
    </template>
  </gl-empty-state>

  <gl-empty-state
    v-else
    :title="$options.i18n.noClosedIssuesTitle"
    :svg-path="emptyStateSvgPath"
    :svg-height="150"
    data-testid="issuable-empty-state"
  />
</template>
