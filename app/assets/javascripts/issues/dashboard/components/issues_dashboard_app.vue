<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/vue_shared/issuable/list/constants';

export default {
  i18n: {
    calendarButtonText: __('Subscribe to calendar'),
    emptyStateTitle: __('Please select at least one filter to see results'),
    rssButtonText: __('Subscribe to RSS feed'),
    searchInputPlaceholder: __('Search or filter results...'),
  },
  IssuableListTabs,
  components: {
    GlButton,
    GlEmptyState,
    IssuableList,
  },
  inject: ['calendarPath', 'emptyStateSvgPath', 'isSignedIn', 'rssPath'],
  data() {
    return {
      issues: [],
      searchTokens: [],
      sortOptions: [],
      state: IssuableStates.Opened,
    };
  },
};
</script>

<template>
  <issuable-list
    namespace="dashboard"
    recent-searches-storage-key="issues"
    :search-input-placeholder="$options.i18n.searchInputPlaceholder"
    :search-tokens="searchTokens"
    :sort-options="sortOptions"
    :issuables="issues"
    :tabs="$options.IssuableListTabs"
    :current-tab="state"
  >
    <template #nav-actions>
      <gl-button :href="rssPath" icon="rss">
        {{ $options.i18n.rssButtonText }}
      </gl-button>
      <gl-button :href="calendarPath" icon="calendar">
        {{ $options.i18n.calendarButtonText }}
      </gl-button>
    </template>

    <template #empty-state>
      <gl-empty-state :svg-path="emptyStateSvgPath" :title="$options.i18n.emptyStateTitle" />
    </template>
  </issuable-list>
</template>
