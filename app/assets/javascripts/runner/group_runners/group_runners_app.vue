<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { updateHistory } from '~/lib/utils/url_utility';
import { formatNumber } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';

import RegistrationDropdown from '../components/registration/registration_dropdown.vue';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerListEmptyState from '../components/runner_list_empty_state.vue';
import RunnerName from '../components/runner_name.vue';
import RunnerStats from '../components/stat/runner_stats.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeTabs from '../components/runner_type_tabs.vue';
import RunnerActionsCell from '../components/cells/runner_actions_cell.vue';

import { pausedTokenConfig } from '../components/search_tokens/paused_token_config';
import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import {
  GROUP_FILTERED_SEARCH_NAMESPACE,
  GROUP_TYPE,
  PROJECT_TYPE,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_STALE,
  I18N_FETCH_ERROR,
} from '../constants';
import groupRunnersQuery from '../graphql/list/group_runners.query.graphql';
import groupRunnersCountQuery from '../graphql/list/group_runners_count.query.graphql';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
  isSearchFiltered,
} from '../runner_search_utils';
import { captureException } from '../sentry_utils';

const countSmartQuery = () => ({
  query: groupRunnersCountQuery,
  fetchPolicy: fetchPolicies.NETWORK_ONLY,
  update(data) {
    return data?.group?.runners?.count;
  },
  error(error) {
    this.reportToSentry(error);
  },
});

const tabCountSmartQuery = ({ type }) => {
  return {
    ...countSmartQuery(),
    variables() {
      return {
        ...this.countVariables,
        type,
      };
    },
  };
};

const statusCountSmartQuery = ({ status, name }) => {
  return {
    ...countSmartQuery(),
    skip() {
      // skip if filtering by status and not using _this_ status as filter
      if (this.countVariables.status && this.countVariables.status !== status) {
        // reset count for given status
        this[name] = null;
        return true;
      }
      return false;
    },
    variables() {
      return {
        ...this.countVariables,
        status,
      };
    },
  };
};

export default {
  name: 'GroupRunnersApp',
  components: {
    GlBadge,
    GlLink,
    RegistrationDropdown,
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerListEmptyState,
    RunnerName,
    RunnerStats,
    RunnerPagination,
    RunnerTypeTabs,
    RunnerActionsCell,
  },
  inject: ['emptyStateSvgPath', 'emptyStateFilteredSvgPath'],
  props: {
    registrationToken: {
      type: String,
      required: true,
    },
    groupFullPath: {
      type: String,
      required: true,
    },
    groupRunnersLimitedCount: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      search: fromUrlQueryToSearch(),
      runners: {
        items: [],
        urlsById: {},
        pageInfo: {},
      },
    };
  },
  apollo: {
    runners: {
      query: groupRunnersQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return this.variables;
      },
      update(data) {
        const { edges = [], pageInfo = {} } = data?.group?.runners || {};

        const items = [];
        const urlsById = {};

        edges.forEach(({ node, webUrl, editUrl }) => {
          items.push(node);
          urlsById[node.id] = {
            web: webUrl,
            edit: editUrl,
          };
        });

        return {
          items,
          urlsById,
          pageInfo,
        };
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },

    // Tabs counts
    allRunnersCount: {
      ...tabCountSmartQuery({ type: null }),
    },
    groupRunnersCount: {
      ...tabCountSmartQuery({ type: GROUP_TYPE }),
    },
    projectRunnersCount: {
      ...tabCountSmartQuery({ type: PROJECT_TYPE }),
    },

    // Runner status summary
    onlineRunnersTotal: {
      ...statusCountSmartQuery({ status: STATUS_ONLINE, name: 'onlineRunnersTotal' }),
    },
    offlineRunnersTotal: {
      ...statusCountSmartQuery({ status: STATUS_OFFLINE, name: 'offlineRunnersTotal' }),
    },
    staleRunnersTotal: {
      ...statusCountSmartQuery({ status: STATUS_STALE, name: 'staleRunnersTotal' }),
    },
  },
  computed: {
    variables() {
      return {
        ...fromSearchToVariables(this.search),
        groupFullPath: this.groupFullPath,
      };
    },
    countVariables() {
      // Exclude pagination variables, leave only filters variables
      const { sort, before, last, after, first, ...countVariables } = this.variables;
      return countVariables;
    },
    runnersLoading() {
      return this.$apollo.queries.runners.loading;
    },
    noRunnersFound() {
      return !this.runnersLoading && !this.runners.items.length;
    },
    searchTokens() {
      return [pausedTokenConfig, statusTokenConfig];
    },
    filteredSearchNamespace() {
      return `${GROUP_FILTERED_SEARCH_NAMESPACE}/${this.groupFullPath}`;
    },
    isSearchFiltered() {
      return isSearchFiltered(this.search);
    },
  },
  watch: {
    search: {
      deep: true,
      handler() {
        // TODO Implement back button reponse using onpopstate
        // See https://gitlab.com/gitlab-org/gitlab/-/issues/333804
        updateHistory({
          url: fromSearchToUrl(this.search),
          title: document.title,
        });
      },
    },
  },
  errorCaptured(error) {
    this.reportToSentry(error);
  },
  methods: {
    tabCount({ runnerType }) {
      let count;
      switch (runnerType) {
        case null:
          count = this.allRunnersCount;
          break;
        case GROUP_TYPE:
          count = this.groupRunnersCount;
          break;
        case PROJECT_TYPE:
          count = this.projectRunnersCount;
          break;
        default:
          return null;
      }
      if (typeof count === 'number') {
        return formatNumber(count);
      }
      return null;
    },
    webUrl(runner) {
      return this.runners.urlsById[runner.id]?.web;
    },
    editUrl(runner) {
      return this.runners.urlsById[runner.id]?.edit;
    },
    refetchFilteredCounts() {
      this.$apollo.queries.allRunnersCount.refetch();
      this.$apollo.queries.groupRunnersCount.refetch();
      this.$apollo.queries.projectRunnersCount.refetch();
    },
    onToggledPaused() {
      // When a runner is Paused, the tab count can
      // become stale, refetch outdated counts.
      this.refetchFilteredCounts();
    },
    onDeleted({ message }) {
      this.$root.$toast?.show(message);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  TABS_RUNNER_TYPES: [GROUP_TYPE, PROJECT_TYPE],
  GROUP_TYPE,
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-align-items-center">
      <runner-type-tabs
        v-model="search"
        :runner-types="$options.TABS_RUNNER_TYPES"
        content-class="gl-display-none"
        nav-class="gl-border-none!"
      >
        <template #title="{ tab }">
          {{ tab.title }}
          <gl-badge v-if="tabCount(tab)" class="gl-ml-1" size="sm">
            {{ tabCount(tab) }}
          </gl-badge>
        </template>
      </runner-type-tabs>

      <registration-dropdown
        class="gl-ml-auto"
        :registration-token="registrationToken"
        :type="$options.GROUP_TYPE"
        right
      />
    </div>

    <runner-filtered-search-bar
      v-model="search"
      :tokens="searchTokens"
      :namespace="filteredSearchNamespace"
    />

    <runner-stats
      :online-runners-count="onlineRunnersTotal"
      :offline-runners-count="offlineRunnersTotal"
      :stale-runners-count="staleRunnersTotal"
    />

    <runner-list-empty-state
      v-if="noRunnersFound"
      :registration-token="registrationToken"
      :is-search-filtered="isSearchFiltered"
      :svg-path="emptyStateSvgPath"
      :filtered-svg-path="emptyStateFilteredSvgPath"
    />
    <template v-else>
      <runner-list :runners="runners.items" :loading="runnersLoading">
        <template #runner-name="{ runner }">
          <gl-link :href="webUrl(runner)">
            <runner-name :runner="runner" />
          </gl-link>
        </template>
        <template #runner-actions-cell="{ runner }">
          <runner-actions-cell
            :runner="runner"
            :edit-url="editUrl(runner)"
            @toggledPaused="onToggledPaused"
            @deleted="onDeleted"
          />
        </template>
      </runner-list>
      <runner-pagination
        v-model="search.pagination"
        class="gl-mt-3"
        :page-info="runners.pageInfo"
      />
    </template>
  </div>
</template>
