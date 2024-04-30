<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { convertToApiParams, convertToSearchQuery, deriveSortKey } from '~/issues/list/utils';
import { __, s__ } from '~/locale';
import {
  OPERATORS_IS,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_SEARCH_WITHIN,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { STATE_CLOSED } from '../../constants';
import { sortOptions, urlSortParams } from '../constants';
import getWorkItemsQuery from '../queries/get_work_items.query.graphql';

const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');

export default {
  issuableListTabs,
  sortOptions,
  components: {
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
  },
  inject: ['fullPath', 'initialSort', 'isSignedIn'],
  data() {
    return {
      error: undefined,
      filterTokens: [],
      sortKey: deriveSortKey({ sort: this.initialSort, sortMap: urlSortParams }),
      state: STATUS_OPEN,
      tabCounts: {},
      workItems: [],
    };
  },
  apollo: {
    workItems: {
      query: getWorkItemsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          sort: this.sortKey,
          state: this.state,
          search: this.searchQuery,
          ...this.apiFilterParams,
        };
      },
      update(data) {
        return data.group.workItems.nodes ?? [];
      },
      result({ data }) {
        const { all, closed, opened } = data?.group.workItemStateCounts ?? {};
        this.tabCounts = {
          [STATUS_OPEN]: opened,
          [STATUS_CLOSED]: closed,
          [STATUS_ALL]: all,
        };
      },
      error(error) {
        this.error = s__(
          'WorkItem|Something went wrong when fetching work items. Please try again.',
        );
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    apiFilterParams() {
      return convertToApiParams(this.filterTokens);
    },
    searchQuery() {
      return convertToSearchQuery(this.filterTokens);
    },
    searchTokens() {
      const preloadedUsers = [];

      if (gon.current_user_id) {
        preloadedUsers.push({
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        });
      }

      return [
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: false,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-author`,
          preloadedUsers,
        },
        {
          type: TOKEN_TYPE_SEARCH_WITHIN,
          title: TOKEN_TITLE_SEARCH_WITHIN,
          icon: 'search',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            { icon: 'title', value: 'TITLE', title: __('Titles') },
            { icon: 'text-description', value: 'DESCRIPTION', title: __('Descriptions') },
          ],
        },
      ];
    },
  },
  methods: {
    getStatus(issue) {
      return issue.state === STATE_CLOSED ? __('Closed') : undefined;
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }

      this.state = state;
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
    },
    handleSort(sortKey) {
      if (this.sortKey === sortKey) {
        return;
      }

      this.sortKey = sortKey;

      if (this.isSignedIn) {
        this.saveSortPreference(sortKey);
      }
    },
    saveSortPreference(sortKey) {
      this.$apollo
        .mutate({
          mutation: setSortPreferenceMutation,
          variables: { input: { issuesSort: sortKey } },
        })
        .then(({ data }) => {
          if (data.userPreferencesUpdate.errors.length) {
            throw new Error(data.userPreferencesUpdate.errors);
          }
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
  },
};
</script>

<template>
  <issuable-list
    :current-tab="state"
    :error="error"
    :initial-sort-by="sortKey"
    :issuables="workItems"
    :issuables-loading="$apollo.queries.workItems.loading"
    namespace="work-items"
    recent-searches-storage-key="issues"
    :search-tokens="searchTokens"
    show-work-item-type-icon
    :sort-options="$options.sortOptions"
    :tab-counts="tabCounts"
    :tabs="$options.issuableListTabs"
    @click-tab="handleClickTab"
    @dismiss-alert="error = undefined"
    @filter="handleFilter"
    @sort="handleSort"
  >
    <template #nav-actions>
      <slot name="nav-actions"></slot>
    </template>

    <template #timeframe="{ issuable = {} }">
      <issue-card-time-info :issue="issuable" />
    </template>

    <template #status="{ issuable }">
      {{ getStatus(issuable) }}
    </template>

    <template #statistics="{ issuable = {} }">
      <issue-card-statistics :issue="issuable" />
    </template>

    <template #list-body>
      <slot name="list-body"></slot>
    </template>
  </issuable-list>
</template>
