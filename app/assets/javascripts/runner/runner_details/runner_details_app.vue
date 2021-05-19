<script>
import { convertToGraphQLId } from '~/graphql_shared/utils';
import RunnerTypeBadge from '../components/runner_type_badge.vue';
import { I18N_DETAILS_TITLE, RUNNER_ENTITY_TYPE } from '../constants';
import getRunnerQuery from '../graphql/get_runner.query.graphql';

export default {
  components: {
    RunnerTypeBadge,
  },
  i18n: {
    I18N_DETAILS_TITLE,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      runner: {},
    };
  },
  apollo: {
    runner: {
      query: getRunnerQuery,
      variables() {
        return {
          id: convertToGraphQLId(RUNNER_ENTITY_TYPE, this.runnerId),
        };
      },
    },
  },
};
</script>
<template>
  <h2 class="page-title">
    {{ sprintf($options.i18n.I18N_DETAILS_TITLE, { runner_id: runnerId }) }}

    <runner-type-badge v-if="runner.runnerType" :type="runner.runnerType" />
  </h2>
</template>
