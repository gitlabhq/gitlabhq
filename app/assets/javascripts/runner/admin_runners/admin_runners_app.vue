<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import { updateHistory } from '~/lib/utils/url_utility';

import RegistrationDropdown from '../components/registration/registration_dropdown.vue';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerName from '../components/runner_name.vue';
import RunnerOnlineStat from '../components/stat/runner_online_stat.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeTabs from '../components/runner_type_tabs.vue';

import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import { tagTokenConfig } from '../components/search_tokens/tag_token_config';
import {
  ADMIN_FILTERED_SEARCH_NAMESPACE,
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_FETCH_ERROR,
} from '../constants';
import getRunnersQuery from '../graphql/get_runners.query.graphql';
import getRunnersCountQuery from '../graphql/get_runners_count.query.graphql';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from '../runner_search_utils';
import { captureException } from '../sentry_utils';

const runnersCountSmartQuery = {
  query: getRunnersCountQuery,
  fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
  update(data) {
    return data?.runners?.count;
  },
  error(error) {
    this.reportToSentry(error);
  },
};

export default {
  name: 'AdminRunnersApp',
  components: {
    GlBadge,
    GlLink,
    RegistrationDropdown,
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerName,
    RunnerOnlineStat,
    RunnerPagination,
    RunnerTypeTabs,
  },
  props: {
    registrationToken: {
      type: String,
      required: true,
    },
    activeRunnersCount: {
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
      query: getRunnersQuery,
      // Runners can be updated by users directly in this list.
      // A "cache and network" policy prevents outdated filtered
      // results.
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
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
    allRunnersCount: {
      ...runnersCountSmartQuery,
      variables() {
        return this.countVariables;
      },
    },
    instanceRunnersCount: {
      ...runnersCountSmartQuery,
      variables() {
        return {
          ...this.countVariables,
          type: INSTANCE_TYPE,
        };
      },
    },
    groupRunnersCount: {
      ...runnersCountSmartQuery,
      variables() {
        return {
          ...this.countVariables,
          type: GROUP_TYPE,
        };
      },
    },
    projectRunnersCount: {
      ...runnersCountSmartQuery,
      variables() {
        return {
          ...this.countVariables,
          type: PROJECT_TYPE,
        };
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
        statusTokenConfig,
        {
          ...tagTokenConfig,
          recentSuggestionsStorageKey: `${this.$options.filteredSearchNamespace}-recent-tags`,
        },
      ];
    },
  },
  watch: {
    search: {
      deep: true,
      handler() {
        // TODO Implement back button response using onpopstate
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
      switch (runnerType) {
        case null:
          return this.allRunnersCount;
        case INSTANCE_TYPE:
          return this.instanceRunnersCount;
        case GROUP_TYPE:
          return this.groupRunnersCount;
        case PROJECT_TYPE:
          return this.projectRunnersCount;
        default:
          return null;
      }
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  filteredSearchNamespace: ADMIN_FILTERED_SEARCH_NAMESPACE,
  INSTANCE_TYPE,
};
</script>
<template>
  <div>
    <runner-online-stat class="gl-py-6 gl-px-5" :value="activeRunnersCount" />

    <div
      class="gl-display-flex gl-align-items-center gl-flex-direction-column-reverse gl-md-flex-direction-row gl-mt-3 gl-md-mt-0"
    >
      <runner-type-tabs
        v-model="search"
        class="gl-w-full"
        content-class="gl-display-none"
        nav-class="gl-border-none!"
      >
        <template #title="{ tab }">
          {{ tab.title }}
          <gl-badge v-if="typeof tabCount(tab) == 'number'" class="gl-ml-1" size="sm">
            {{ tabCount(tab) }}
          </gl-badge>
        </template>
      </runner-type-tabs>

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

    <div v-if="noRunnersFound" class="gl-text-center gl-p-5">
      {{ __('No runners found') }}
    </div>
    <template v-else>
      <runner-list :runners="runners.items" :loading="runnersLoading">
        <template #runner-name="{ runner }">
          <gl-link :href="runner.adminUrl">
            <runner-name :runner="runner" />
          </gl-link>
        </template>
      </runner-list>
      <runner-pagination v-model="search.pagination" :page-info="runners.pageInfo" />
    </template>
  </div>
</template>
