<script>
import { GlLink } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { updateHistory } from '~/lib/utils/url_utility';
import { fetchPolicies } from '~/lib/graphql';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { upgradeStatusTokenConfig } from 'ee_else_ce/runner/components/search_tokens/upgrade_status_token_config';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
  isSearchFiltered,
} from 'ee_else_ce/runner/runner_search_utils';
import runnersAdminQuery from 'ee_else_ce/runner/graphql/list/admin_runners.query.graphql';

import RegistrationDropdown from '../components/registration/registration_dropdown.vue';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerBulkDelete from '../components/runner_bulk_delete.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerListEmptyState from '../components/runner_list_empty_state.vue';
import RunnerName from '../components/runner_name.vue';
import RunnerStats from '../components/stat/runner_stats.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeTabs from '../components/runner_type_tabs.vue';
import RunnerActionsCell from '../components/cells/runner_actions_cell.vue';

import { pausedTokenConfig } from '../components/search_tokens/paused_token_config';
import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import { tagTokenConfig } from '../components/search_tokens/tag_token_config';
import { ADMIN_FILTERED_SEARCH_NAMESPACE, INSTANCE_TYPE, I18N_FETCH_ERROR } from '../constants';
import { captureException } from '../sentry_utils';

export default {
  name: 'AdminRunnersApp',
  components: {
    GlLink,
    RegistrationDropdown,
    RunnerFilteredSearchBar,
    RunnerBulkDelete,
    RunnerList,
    RunnerListEmptyState,
    RunnerName,
    RunnerStats,
    RunnerPagination,
    RunnerTypeTabs,
    RunnerActionsCell,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['emptyStateSvgPath', 'emptyStateFilteredSvgPath', 'localMutations'],
  props: {
    registrationToken: {
      type: String,
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
      query: runnersAdminQuery,
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
      return [
        pausedTokenConfig,
        statusTokenConfig,
        {
          ...tagTokenConfig,
          recentSuggestionsStorageKey: `${this.$options.filteredSearchNamespace}-recent-tags`,
        },
        upgradeStatusTokenConfig,
      ];
    },
    isBulkDeleteEnabled() {
      // Feature flag: admin_runners_bulk_delete
      // Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/353981
      return this.glFeatures.adminRunnersBulkDelete;
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
  errorCaptured(error) {
    this.reportToSentry(error);
  },
  methods: {
    onToggledPaused() {
      // When a runner becomes Paused, the tab count can
      // become stale, refetch outdated counts.
      this.$refs['runner-type-tabs'].refetch();
    },
    onDeleted({ message }) {
      this.$root.$toast?.show(message);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
    onChecked({ runner, isChecked }) {
      this.localMutations.setRunnerChecked({
        runner,
        isChecked,
      });
    },
  },
  filteredSearchNamespace: ADMIN_FILTERED_SEARCH_NAMESPACE,
  INSTANCE_TYPE,
};
</script>
<template>
  <div>
    <div
      class="gl-display-flex gl-align-items-center gl-flex-direction-column-reverse gl-md-flex-direction-row gl-mt-3 gl-md-mt-0"
    >
      <runner-type-tabs
        ref="runner-type-tabs"
        v-model="search"
        :count-scope="$options.INSTANCE_TYPE"
        :count-variables="countVariables"
        class="gl-w-full"
        content-class="gl-display-none"
        nav-class="gl-border-none!"
      />

      <registration-dropdown
        class="gl-w-full gl-sm-w-auto gl-mr-auto"
        :registration-token="registrationToken"
        :type="$options.INSTANCE_TYPE"
        right
      />
    </div>

    <runner-filtered-search-bar
      v-model="search"
      :tokens="searchTokens"
      :namespace="$options.filteredSearchNamespace"
    />

    <runner-stats :scope="$options.INSTANCE_TYPE" :variables="countVariables" />

    <runner-list-empty-state
      v-if="noRunnersFound"
      :registration-token="registrationToken"
      :is-search-filtered="isSearchFiltered"
      :svg-path="emptyStateSvgPath"
      :filtered-svg-path="emptyStateFilteredSvgPath"
    />
    <template v-else>
      <runner-bulk-delete v-if="isBulkDeleteEnabled" />
      <runner-list
        :runners="runners.items"
        :loading="runnersLoading"
        :checkable="isBulkDeleteEnabled"
        @checked="onChecked"
      >
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
      <runner-pagination
        v-model="search.pagination"
        class="gl-mt-3"
        :page-info="runners.pageInfo"
      />
    </template>
  </div>
</template>
