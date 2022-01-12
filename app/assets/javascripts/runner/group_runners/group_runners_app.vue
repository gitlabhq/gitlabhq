<script>
import { GlLink } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import { updateHistory } from '~/lib/utils/url_utility';
import { formatNumber, sprintf, s__ } from '~/locale';

import RegistrationDropdown from '../components/registration/registration_dropdown.vue';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerName from '../components/runner_name.vue';
import RunnerOnlineStat from '../components/stat/runner_online_stat.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeTabs from '../components/runner_type_tabs.vue';

import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import {
  I18N_FETCH_ERROR,
  GROUP_FILTERED_SEARCH_NAMESPACE,
  GROUP_TYPE,
  GROUP_RUNNER_COUNT_LIMIT,
} from '../constants';
import getGroupRunnersQuery from '../graphql/get_group_runners.query.graphql';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from '../runner_search_utils';
import { captureException } from '../sentry_utils';

export default {
  name: 'GroupRunnersApp',
  components: {
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
        webUrls: [],
        items: [],
        pageInfo: {},
      },
    };
  },
  apollo: {
    runners: {
      query: getGroupRunnersQuery,
      // Runners can be updated by users directly in this list.
      // A "cache and network" policy prevents outdated filtered
      // results.
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.variables;
      },
      update(data) {
        const { runners } = data?.group || {};

        return {
          webUrls: runners?.edges.map(({ webUrl }) => webUrl) || [],
          items: runners?.edges.map(({ node }) => node) || [],
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
      return {
        ...fromSearchToVariables(this.search),
        groupFullPath: this.groupFullPath,
      };
    },
    runnersLoading() {
      return this.$apollo.queries.runners.loading;
    },
    noRunnersFound() {
      return !this.runnersLoading && !this.runners.items.length;
    },
    groupRunnersCount() {
      if (this.groupRunnersLimitedCount > GROUP_RUNNER_COUNT_LIMIT) {
        return `${formatNumber(GROUP_RUNNER_COUNT_LIMIT)}+`;
      }
      return formatNumber(this.groupRunnersLimitedCount);
    },
    runnerCountMessage() {
      return sprintf(s__('Runners|Runners in this group: %{groupRunnersCount}'), {
        groupRunnersCount: this.groupRunnersCount,
      });
    },
    searchTokens() {
      return [statusTokenConfig];
    },
    filteredSearchNamespace() {
      return `${GROUP_FILTERED_SEARCH_NAMESPACE}/${this.groupFullPath}`;
    },
  },
  watch: {
    search: {
      deep: true,
      handler() {
        // TODO Implement back button reponse using onpopstate
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
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  GROUP_TYPE,
};
</script>

<template>
  <div>
    <runner-online-stat class="gl-py-6 gl-px-5" :value="groupRunnersCount" />

    <div class="gl-display-flex gl-align-items-center">
      <runner-type-tabs
        v-model="search"
        content-class="gl-display-none"
        nav-class="gl-border-none!"
      />

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

    <div v-if="noRunnersFound" class="gl-text-center gl-p-5">
      {{ __('No runners found') }}
    </div>
    <template v-else>
      <runner-list :runners="runners.items" :loading="runnersLoading">
        <template #runner-name="{ runner, index }">
          <gl-link :href="runners.webUrls[index]">
            <runner-name :runner="runner" />
          </gl-link>
        </template>
      </runner-list>
      <runner-pagination v-model="search.pagination" :page-info="runners.pageInfo" />
    </template>
  </div>
</template>
