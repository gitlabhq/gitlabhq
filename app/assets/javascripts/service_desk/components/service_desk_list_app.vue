<script>
import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { fetchPolicies } from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import {
  OPERATORS_IS_NOT,
  OPERATORS_IS_NOT_OR,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import searchUsersQuery from '~/issues/list/queries/search_users.query.graphql';
import searchLabelsQuery from '~/issues/list/queries/search_labels.query.graphql';
import searchMilestonesQuery from '~/issues/list/queries/search_milestones.query.graphql';
import getServiceDeskIssuesQuery from '../queries/get_service_desk_issues.query.graphql';
import getServiceDeskIssuesCounts from '../queries/get_service_desk_issues_counts.query.graphql';
import {
  errorFetchingCounts,
  errorFetchingIssues,
  noSearchNoFilterTitle,
  searchPlaceholder,
  SERVICE_DESK_BOT_USERNAME,
  MAX_LIST_SIZE,
  STATUS_OPEN,
  STATUS_CLOSED,
  STATUS_ALL,
  WORKSPACE_PROJECT,
} from '../constants';
import {
  searchWithinTokenBase,
  assigneeTokenBase,
  milestoneTokenBase,
  labelTokenBase,
  releaseTokenBase,
  reactionTokenBase,
  confidentialityTokenBase,
} from '../search_tokens';
import InfoBanner from './info_banner.vue';

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
    InfoBanner,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'releasesPath',
    'autocompleteAwardEmojisPath',
    'hasIterationsFeature',
    'groupPath',
    'emptyStateSvgPath',
    'isProject',
    'isSignedIn',
    'fullPath',
    'isServiceDeskSupported',
    'hasAnyIssues',
  ],
  data() {
    return {
      serviceDeskIssues: [],
      serviceDeskIssuesCounts: {},
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
        if (!data) {
          return;
        }
        this.pageInfo = data?.project.issues.pageInfo ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingIssues;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasAnyIssues;
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
    isInfoBannerVisible() {
      return this.isServiceDeskSupported && this.hasAnyIssues;
    },
    hasOrFeature() {
      return this.glFeatures.orIssuableQueries;
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

      const tokens = [
        {
          ...searchWithinTokenBase,
        },
        {
          ...assigneeTokenBase,
          operators: this.hasOrFeature ? OPERATORS_IS_NOT_OR : OPERATORS_IS_NOT,
          fetchUsers: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
        },
        {
          ...milestoneTokenBase,
          fetchMilestones: this.fetchMilestones,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-milestone`,
        },
        {
          ...labelTokenBase,
          operators: this.hasOrFeature ? OPERATORS_IS_NOT_OR : OPERATORS_IS_NOT,
          fetchLabels: this.fetchLabels,
          fetchLatestLabels: this.glFeatures.frontendCaching ? this.fetchLatestLabels : null,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-label`,
        },
      ];

      if (this.isProject) {
        tokens.push({
          ...releaseTokenBase,
          fetchReleases: this.fetchReleases,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-release`,
        });
      }

      if (this.isSignedIn) {
        tokens.push({
          ...reactionTokenBase,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-my_reaction`,
        });

        tokens.push({
          ...confidentialityTokenBase,
        });
      }

      tokens.sort((a, b) => a.title.localeCompare(b.title));

      return tokens;
    },
  },
  created() {
    this.cache = {};
  },
  methods: {
    fetchWithCache(path, cacheName, searchKey, search) {
      if (this.cache[cacheName]) {
        const data = search
          ? fuzzaldrinPlus.filter(this.cache[cacheName], search, { key: searchKey })
          : this.cache[cacheName].slice(0, MAX_LIST_SIZE);
        return Promise.resolve(data);
      }

      return axios.get(path).then(({ data }) => {
        this.cache[cacheName] = data;
        return data.slice(0, MAX_LIST_SIZE);
      });
    },
    fetchUsers(search) {
      return this.$apollo
        .query({
          query: searchUsersQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
        })
        .then(({ data }) =>
          data[WORKSPACE_PROJECT]?.[`${WORKSPACE_PROJECT}Members`].nodes.map(
            (member) => member.user,
          ),
        );
    },
    fetchMilestones(search) {
      return this.$apollo
        .query({
          query: searchMilestonesQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
        })
        .then(({ data }) => data[WORKSPACE_PROJECT]?.milestones.nodes);
    },
    fetchEmojis(search) {
      return this.fetchWithCache(this.autocompleteAwardEmojisPath, 'emojis', 'name', search);
    },
    fetchReleases(search) {
      return this.fetchWithCache(this.releasesPath, 'releases', 'tag', search);
    },
    fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
          fetchPolicy,
        })
        .then(({ data }) => data[WORKSPACE_PROJECT]?.labels.nodes)
        .then((labels) =>
          // TODO remove once we can search by title-only on the backend
          // https://gitlab.com/gitlab-org/gitlab/-/issues/346353
          labels.filter((label) => label.title.toLowerCase().includes(search.toLowerCase())),
        );
    },
    fetchLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search);
    },
    fetchLatestLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search, fetchPolicies.NETWORK_ONLY);
    },
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
    <info-banner v-if="isInfoBannerVisible" />
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
