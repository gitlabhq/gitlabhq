<script>
import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { fetchPolicies } from '~/lib/graphql';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { STATUS_OPEN, STATUS_CLOSED, STATUS_ALL } from '~/issues/constants';
import getServiceDeskIssuesQuery from '../queries/get_service_desk_issues.query.graphql';
import getServiceDeskIssuesCounts from '../queries/get_service_desk_issues_counts.query.graphql';
import {
  errorFetchingCounts,
  errorFetchingIssues,
  noSearchNoFilterTitle,
  searchPlaceholder,
  SERVICE_DESK_BOT_USERNAME,
} from '../constants';

export default {
  i18n: {
    errorFetchingCounts,
    errorFetchingIssues,
    noSearchNoFilterTitle,
    searchPlaceholder,
  },
  issuableListTabs,
  components: {
    GlEmptyState,
    IssuableList,
  },
  inject: ['emptyStateSvgPath', 'isProject', 'isSignedIn', 'fullPath'],
  data() {
    return {
      serviceDeskIssues: [],
      serviceDeskIssuesCounts: {},
      searchTokens: [],
      sortOptions: [],
      state: STATUS_OPEN,
      issuesError: null,
    };
  },
  apollo: {
    serviceDeskIssues: {
      query: getServiceDeskIssuesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project.issues.nodes ?? [];
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      // We need this for handling loading state when using frontend cache
      // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106004#note_1217325202 for details
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        this.pageInfo = data?.project.issues.pageInfo ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingIssues;
        Sentry.captureException(error);
      },
    },
    serviceDeskIssuesCounts: {
      query: getServiceDeskIssuesCounts,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.project ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingCounts;
        Sentry.captureException(error);
      },
      context: {
        isSingleRequest: true,
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.fullPath,
        isProject: this.isProject,
        isSignedIn: this.isSignedIn,
        authorUsername: SERVICE_DESK_BOT_USERNAME,
        state: this.state,
      };
    },
    tabCounts() {
      const { openedIssues, closedIssues, allIssues } = this.serviceDeskIssuesCounts;
      return {
        [STATUS_OPEN]: openedIssues?.count,
        [STATUS_CLOSED]: closedIssues?.count,
        [STATUS_ALL]: allIssues?.count,
      };
    },
  },
  methods: {
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }
      this.state = state;
    },
  },
};
</script>

<template>
  <section>
    <issuable-list
      namespace="service-desk"
      recent-searches-storage-key="issues"
      :error="issuesError"
      :search-input-placeholder="$options.i18n.searchPlaceholder"
      :search-tokens="searchTokens"
      :sort-options="sortOptions"
      :issuables="serviceDeskIssues"
      :tabs="$options.issuableListTabs"
      :tab-counts="tabCounts"
      :current-tab="state"
      @click-tab="handleClickTab"
    >
      <template #empty-state>
        <gl-empty-state
          :svg-path="emptyStateSvgPath"
          :title="$options.i18n.noSearchNoFilterTitle"
        />
      </template>
    </issuable-list>
  </section>
</template>
