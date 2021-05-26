<script>
import * as Sentry from '@sentry/browser';
import { updateHistory } from '~/lib/utils/url_utility';
import RunnerFilteredSearchBar from '../components/runner_filtered_search_bar.vue';
import RunnerList from '../components/runner_list.vue';
import RunnerManualSetupHelp from '../components/runner_manual_setup_help.vue';
import RunnerTypeHelp from '../components/runner_type_help.vue';
import getRunnersQuery from '../graphql/get_runners.query.graphql';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from './filtered_search_utils';

export default {
  components: {
    RunnerFilteredSearchBar,
    RunnerList,
    RunnerManualSetupHelp,
    RunnerTypeHelp,
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
      runners: [],
    };
  },
  apollo: {
    runners: {
      query: getRunnersQuery,
      variables() {
        return this.variables;
      },
      update({ runners }) {
        return runners?.nodes || [];
      },
      error(err) {
        this.captureException(err);
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
      return !this.runnersLoading && !this.runners.length;
    },
  },
  watch: {
    search() {
      // TODO Implement back button reponse using onpopstate

      updateHistory({
        url: fromSearchToUrl(this.search),
        title: document.title,
      });
    },
  },
  errorCaptured(err) {
    this.captureException(err);
  },
  methods: {
    captureException(err) {
      Sentry.withScope((scope) => {
        scope.setTag('component', 'runner_list_app');
        Sentry.captureException(err);
      });
    },
  },
};
</script>
<template>
  <div>
    <div class="row">
      <div class="col-sm-6">
        <runner-type-help />
      </div>
      <div class="col-sm-6">
        <runner-manual-setup-help :registration-token="registrationToken" />
      </div>
    </div>

    <runner-filtered-search-bar v-model="search" namespace="admin_runners" />

    <div v-if="noRunnersFound" class="gl-text-center gl-p-5">
      {{ __('No runners found') }}
    </div>
    <runner-list
      v-else
      :runners="runners"
      :loading="runnersLoading"
      :active-runners-count="activeRunnersCount"
    />
  </div>
</template>
