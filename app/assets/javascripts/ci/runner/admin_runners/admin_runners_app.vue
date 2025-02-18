<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { updateHistory } from '~/lib/utils/url_utility';
import { fetchPolicies } from '~/lib/graphql';
import { upgradeStatusTokenConfig } from 'ee_else_ce/ci/runner/components/search_tokens/upgrade_status_token_config';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
  isSearchFiltered,
} from 'ee_else_ce/ci/runner/runner_search_utils';
import allRunnersQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners.query.graphql';
import allRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners_count.query.graphql';
import usersSearchAllQuery from '~/graphql_shared/queries/users_search_all.query.graphql';

import RunnerListHeader from '../components/runner_list_header.vue';
import RegistrationDropdown from '../components/registration/registration_dropdown.vue';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerListEmptyState from '../components/runner_list_empty_state.vue';
import RunnerName from '../components/runner_name.vue';
import RunnerStats from '../components/stat/runner_stats.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeTabs from '../components/runner_type_tabs.vue';
import RunnerActionsCell from '../components/cells/runner_actions_cell.vue';
import RunnerJobStatusBadge from '../components/runner_job_status_badge.vue';

import { pausedTokenConfig } from '../components/search_tokens/paused_token_config';
import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import { tagTokenConfig } from '../components/search_tokens/tag_token_config';
import { versionTokenConfig } from '../components/search_tokens/version_token_config';
import { creatorTokenConfig } from '../components/search_tokens/creator_token_config';
import {
  ADMIN_FILTERED_SEARCH_NAMESPACE,
  INSTANCE_TYPE,
  I18N_FETCH_ERROR,
  FILTER_CSS_CLASSES,
  JOBS_ROUTE_PATH,
} from '../constants';
import { captureException } from '../sentry_utils';

export default {
  name: 'AdminRunnersApp',
  components: {
    GlButton,
    GlLink,
    RunnerListHeader,
    RegistrationDropdown,
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerListEmptyState,
    RunnerName,
    RunnerStats,
    RunnerPagination,
    RunnerTypeTabs,
    RunnerActionsCell,
    RunnerJobStatusBadge,
    RunnerDashboardLink: () =>
      import('ee_component/ci/runner/components/runner_dashboard_link.vue'),
  },
  props: {
    newRunnerPath: {
      type: String,
      required: true,
    },
    allowRegistrationToken: {
      type: Boolean,
      required: false,
      default: false,
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
    canAdminRunners: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      search: fromUrlQueryToSearch(),
      runners: {
        items: [],
        pageInfo: {},
      },
    };
  },
  apollo: {
    runners: {
      query: allRunnersQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return this.variables;
      },
      update(data) {
        const { runners } = data;
        return {
          items: runners?.nodes || [],
          pageInfo: runners?.pageInfo || {},
        };
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },
  },
  computed: {
    variables() {
      return fromSearchToVariables(this.search);
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
      const preloadedUsers = [];
      if (gon.current_user_id) {
        preloadedUsers.push({
          id: gon.current_user_id,
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        });
      }

      return [
        pausedTokenConfig,
        statusTokenConfig,
        versionTokenConfig,
        {
          ...creatorTokenConfig,
          fetchUsers: (search) => {
            return this.$apollo
              .query({
                query: usersSearchAllQuery,
                variables: { search },
              })
              .then(({ data }) => data.users.nodes);
          },
          defaultUsers: [],
          preloadedUsers,
        },
        {
          ...tagTokenConfig,
          recentSuggestionsStorageKey: `${this.$options.filteredSearchNamespace}-recent-tags`,
        },
        upgradeStatusTokenConfig,
      ];
    },
    isSearchFiltered() {
      return isSearchFiltered(this.search);
    },
  },
  watch: {
    search: {
      deep: true,
      handler() {
        // TODO Implement back button response using onpopstate
        // See: https://gitlab.com/gitlab-org/gitlab/-/issues/333804
        updateHistory({
          url: fromSearchToUrl(this.search),
          title: document.title,
        });
      },
    },
  },
  methods: {
    jobsUrl(runner) {
      const url = new URL(runner.adminUrl);
      url.hash = `#${JOBS_ROUTE_PATH}`;

      return url.href;
    },
    onToggledPaused() {
      // When a runner becomes Paused, the tab count can
      // become stale, refetch outdated counts.
      this.refetchCounts();
    },
    onDeleted({ message }) {
      this.refetchCounts();
      this.$root.$toast?.show(message);
    },
    refetchCounts() {
      this.$apollo.getClient().refetchQueries({ include: [allRunnersCountQuery] });
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
    onPaginationInput(value) {
      this.search.pagination = value;
    },
  },
  filteredSearchNamespace: ADMIN_FILTERED_SEARCH_NAMESPACE,
  INSTANCE_TYPE,
  FILTER_CSS_CLASSES,
};
</script>
<template>
  <div>
    <runner-list-header>
      <template #title>{{ s__('Runners|Runners') }}</template>
      <template #actions>
        <runner-dashboard-link />
        <gl-button v-if="canAdminRunners" :href="newRunnerPath" variant="confirm">
          {{ s__('Runners|New instance runner') }}
        </gl-button>
        <registration-dropdown
          v-if="canAdminRunners"
          :allow-registration-token="allowRegistrationToken"
          :registration-token="registrationToken"
          :type="$options.INSTANCE_TYPE"
        />
      </template>
    </runner-list-header>

    <runner-type-tabs
      v-model="search"
      :count-scope="$options.INSTANCE_TYPE"
      :count-variables="countVariables"
    />

    <runner-filtered-search-bar
      v-model="search"
      :class="$options.FILTER_CSS_CLASSES"
      :tokens="searchTokens"
      :namespace="$options.filteredSearchNamespace"
    />

    <runner-stats :scope="$options.INSTANCE_TYPE" :variables="countVariables" />

    <runner-list-empty-state
      v-if="noRunnersFound"
      :registration-token="registrationToken"
      :is-search-filtered="isSearchFiltered"
      :new-runner-path="newRunnerPath"
    />
    <template v-else>
      <runner-list
        :runners="runners.items"
        :loading="runnersLoading"
        :checkable="canAdminRunners"
        @deleted="onDeleted"
      >
        <template #runner-job-status-badge="{ runner }">
          <runner-job-status-badge
            :href="jobsUrl(runner)"
            :job-status="runner.jobExecutionStatus"
          />
        </template>
        <template #runner-name="{ runner }">
          <gl-link :href="runner.adminUrl">
            <runner-name :runner="runner" />
          </gl-link>
        </template>
        <template #runner-actions-cell="{ runner }">
          <runner-actions-cell
            :runner="runner"
            :edit-url="runner.editAdminUrl"
            @toggledPaused="onToggledPaused"
            @deleted="onDeleted"
          />
        </template>
      </runner-list>
    </template>

    <runner-pagination
      class="gl-mt-3"
      :disabled="runnersLoading"
      :page-info="runners.pageInfo"
      @input="onPaginationInput"
    />
  </div>
</template>
