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
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import groupRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/group_runners_count.query.graphql';
import groupRunnersQuery from 'ee_else_ce/ci/runner/graphql/list/group_runners.query.graphql';

import RegistrationDropdown from '../components/registration/registration_dropdown.vue';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerListEmptyState from '../components/runner_list_empty_state.vue';
import RunnerName from '../components/runner_name.vue';
import RunnerStats from '../components/stat/runner_stats.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeTabs from '../components/runner_type_tabs.vue';
import RunnerActionsCell from '../components/cells/runner_actions_cell.vue';
import RunnerMembershipToggle from '../components/runner_membership_toggle.vue';
import RunnerJobStatusBadge from '../components/runner_job_status_badge.vue';

import { pausedTokenConfig } from '../components/search_tokens/paused_token_config';
import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import { tagTokenConfig } from '../components/search_tokens/tag_token_config';
import {
  GROUP_FILTERED_SEARCH_NAMESPACE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_FETCH_ERROR,
  FILTER_CSS_CLASSES,
  JOBS_ROUTE_PATH,
} from '../constants';
import { captureException } from '../sentry_utils';

export default {
  name: 'GroupRunnersApp',
  components: {
    GlButton,
    GlLink,
    RegistrationDropdown,
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerListEmptyState,
    RunnerName,
    RunnerMembershipToggle,
    RunnerStats,
    RunnerPagination,
    RunnerTypeTabs,
    RunnerActionsCell,
    RunnerJobStatusBadge,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['emptyStateSvgPath', 'emptyStateFilteredSvgPath'],
  props: {
    newRunnerPath: {
      type: String,
      required: false,
      default: null,
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
    groupFullPath: {
      type: String,
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
      context: {
        isSingleRequest: true,
      },
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
    filteredSearchNamespace() {
      return `${GROUP_FILTERED_SEARCH_NAMESPACE}/${this.groupFullPath}`;
    },
    searchTokens() {
      return [
        pausedTokenConfig,
        statusTokenConfig,
        {
          ...tagTokenConfig,
          suggestionsDisabled: true,
        },
        upgradeStatusTokenConfig,
      ];
    },
    isSearchFiltered() {
      return isSearchFiltered(this.search);
    },
    shouldShowCreateRunnerWorkflow() {
      // create_runner_workflow_for_namespace feature flag
      return this.glFeatures.createRunnerWorkflowForNamespace;
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
    webUrl(runner) {
      return this.runners.urlsById[runner.id]?.web;
    },
    editUrl(runner) {
      return this.runners.urlsById[runner.id]?.edit;
    },
    jobsUrl(runner) {
      const url = new URL(this.webUrl(runner));
      url.hash = `#${JOBS_ROUTE_PATH}`;

      return url.href;
    },
    refetchCounts() {
      this.$apollo.getClient().refetchQueries({ include: [groupRunnersCountQuery] });
    },
    onToggledPaused() {
      // When a runner becomes Paused, the tab count can
      // become stale, refetch outdated counts.
      this.refetchCounts();
    },
    onDeleted({ message }) {
      this.$root.$toast?.show(message);
      this.refetchCounts();
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
    onPaginationInput(value) {
      this.search.pagination = value;
    },
  },
  TABS_RUNNER_TYPES: [GROUP_TYPE, PROJECT_TYPE],
  GROUP_TYPE,
  FILTER_CSS_CLASSES,
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
        :count-scope="$options.GROUP_TYPE"
        :count-variables="countVariables"
        :runner-types="$options.TABS_RUNNER_TYPES"
        class="gl-w-full"
        content-class="gl-display-none"
        nav-class="gl-border-none!"
      />

      <div class="gl-w-full gl-md-w-auto gl-display-flex">
        <gl-button
          v-if="shouldShowCreateRunnerWorkflow && newRunnerPath"
          :href="newRunnerPath"
          variant="confirm"
        >
          {{ s__('Runners|New group runner') }}
        </gl-button>
        <registration-dropdown
          v-if="registrationToken"
          class="gl-ml-3"
          :registration-token="registrationToken"
          :type="$options.GROUP_TYPE"
          right
        />
      </div>
    </div>
    <div
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-gap-3"
      :class="$options.FILTER_CSS_CLASSES"
    >
      <runner-filtered-search-bar
        v-model="search"
        :tokens="searchTokens"
        :namespace="filteredSearchNamespace"
        class="gl-flex-grow-1 gl-align-self-stretch"
      />
      <runner-membership-toggle
        v-model="search.membership"
        class="gl-align-self-end gl-md-align-self-center"
      />
    </div>

    <runner-stats :scope="$options.GROUP_TYPE" :variables="countVariables" />

    <runner-list-empty-state
      v-if="noRunnersFound"
      :registration-token="registrationToken"
      :is-search-filtered="isSearchFiltered"
      :new-runner-path="newRunnerPath"
      :svg-path="emptyStateSvgPath"
      :filtered-svg-path="emptyStateFilteredSvgPath"
    />
    <template v-else>
      <runner-list
        :runners="runners.items"
        :checkable="true"
        :loading="runnersLoading"
        @deleted="onDeleted"
      >
        <template #runner-job-status-badge="{ runner }">
          <runner-job-status-badge
            :href="jobsUrl(runner)"
            :job-status="runner.jobExecutionStatus"
          />
        </template>
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
    </template>

    <runner-pagination
      class="gl-mt-3"
      :disabled="runnersLoading"
      :page-info="runners.pageInfo"
      @input="onPaginationInput"
    />
  </div>
</template>
