<script>
import createFlash from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import { updateHistory } from '~/lib/utils/url_utility';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerManualSetupHelp from '../components/runner_manual_setup_help.vue';
import RunnerPagination from '../components/runner_pagination.vue';
import RunnerTypeHelp from '../components/runner_type_help.vue';
import { INSTANCE_TYPE, I18N_FETCH_ERROR } from '../constants';
import getRunnersQuery from '../graphql/get_runners.query.graphql';
import { captureException } from '../sentry_utils';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from './runner_search_utils';

export default {
  name: 'RunnerListApp',
  components: {
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerManualSetupHelp,
    RunnerTypeHelp,
    RunnerPagination,
  },
  props: {
    activeRunnersCount: {
      type: Number,
      required: true,
    },
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
        createFlash({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },
  },
  computed: {
    variables() {
      return fromSearchToVariables(this.search);
    },
    runnersLoading() {
      return this.$apollo.queries.runners.loading;
    },
    noRunnersFound() {
      return !this.runnersLoading && !this.runners.items.length;
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
  INSTANCE_TYPE,
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
          :type="$options.INSTANCE_TYPE"
        />
      </div>
    </div>

    <runner-filtered-search-bar
      v-model="search"
      namespace="admin_runners"
      :active-runners-count="activeRunnersCount"
    />

    <div v-if="noRunnersFound" class="gl-text-center gl-p-5">
      {{ __('No runners found') }}
    </div>
    <template v-else>
      <runner-list :runners="runners.items" :loading="runnersLoading" />
      <runner-pagination v-model="search.pagination" :page-info="runners.pageInfo" />
    </template>
  </div>
</template>
