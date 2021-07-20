<script>
import createFlash from '~/flash';
import { TYPE_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { sprintf } from '~/locale';
import RunnerTypeAlert from '../components/runner_type_alert.vue';
import RunnerTypeBadge from '../components/runner_type_badge.vue';
import RunnerUpdateForm from '../components/runner_update_form.vue';
import { I18N_DETAILS_TITLE, I18N_FETCH_ERROR } from '../constants';
import getRunnerQuery from '../graphql/get_runner.query.graphql';
import { captureException } from '../sentry_utils';

export default {
  name: 'RunnerDetailsApp',
  components: {
    RunnerTypeAlert,
    RunnerTypeBadge,
    RunnerUpdateForm,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      runner: null,
    };
  },
  apollo: {
    runner: {
      query: getRunnerQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPE_CI_RUNNER, this.runnerId),
        };
      },
      error(error) {
        createFlash({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },
  },
  computed: {
    pageTitle() {
      return sprintf(I18N_DETAILS_TITLE, { runner_id: this.runnerId });
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
};
</script>
<template>
  <div>
    <h2 class="page-title">
      {{ pageTitle }} <runner-type-badge v-if="runner" :type="runner.runnerType" />
    </h2>

    <runner-type-alert v-if="runner" :type="runner.runnerType" />

    <runner-update-form :runner="runner" class="gl-my-5" />
  </div>
</template>
