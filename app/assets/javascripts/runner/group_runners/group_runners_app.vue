<script>
import createFlash from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import { updateHistory } from '~/lib/utils/url_utility';
import { formatNumber, sprintf, s__ } from '~/locale';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerManualSetupHelp from '../components/runner_manual_setup_help.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeHelp from '../components/runner_type_help.vue';
import { statusTokenConfig } from '../components/search_tokens/status_token_config';
import { typeTokenConfig } from '../components/search_tokens/type_token_config';
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
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerManualSetupHelp,
    RunnerTypeHelp,
    RunnerPagination,
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
          items: runners?.nodes || [],
          pageInfo: runners?.pageInfo || {},
        };
      },
      error(error) {
        createFlash({ message: I18N_FETCH_ERROR });

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
      return [statusTokenConfig, typeTokenConfig];
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
    <div class="row">
      <div class="col-sm-6">
        <runner-type-help />
      </div>
      <div class="col-sm-6">
        <runner-manual-setup-help
          :registration-token="registrationToken"
          :type="$options.GROUP_TYPE"
        />
      </div>
    </div>

    <runner-filtered-search-bar
      v-model="search"
      :tokens="searchTokens"
      :namespace="filteredSearchNamespace"
    >
      <template #runner-count>
        {{ runnerCountMessage }}
      </template>
    </runner-filtered-search-bar>

    <div v-if="noRunnersFound" class="gl-text-center gl-p-5">
      {{ __('No runners found') }}
    </div>
    <template v-else>
      <runner-list :runners="runners.items" :loading="runnersLoading" />
      <runner-pagination v-model="search.pagination" :page-info="runners.pageInfo" />
    </template>
  </div>
</template>
