<script>
import { createAlert } from '~/alert';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import RunnerHeader from '../components/runner_header.vue';
import RunnerDetailsTabs from '../components/runner_details_tabs.vue';

import { I18N_FETCH_ERROR } from '../constants';
import runnerQuery from '../graphql/show/runner.query.graphql';
import { captureException } from '../sentry_utils';

export default {
  name: 'ProjectRunnerShowApp',
  components: {
    RunnerHeader,
    RunnerDetailsTabs,
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
      query: runnerQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_CI_RUNNER, this.runnerId),
        };
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },
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
    <runner-header v-if="runner" :runner="runner" />
    <runner-details-tabs v-if="runner" :runner="runner" />
  </div>
</template>
