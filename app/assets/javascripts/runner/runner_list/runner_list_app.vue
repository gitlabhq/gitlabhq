<script>
import * as Sentry from '@sentry/browser';
import RunnerList from '../components/runner_list.vue';
import RunnerManualSetupHelp from '../components/runner_manual_setup_help.vue';
import RunnerTypeHelp from '../components/runner_type_help.vue';
import getRunnersQuery from '../graphql/get_runners.query.graphql';

export default {
  components: {
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
      runners: [],
    };
  },
  apollo: {
    runners: {
      query: getRunnersQuery,
      update({ runners }) {
        return runners?.nodes || [];
      },
      error(err) {
        this.captureException(err);
      },
    },
  },
  computed: {
    runnersLoading() {
      return this.$apollo.queries.runners.loading;
    },
    noRunnersFound() {
      return !this.runnersLoading && !this.runners.length;
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
