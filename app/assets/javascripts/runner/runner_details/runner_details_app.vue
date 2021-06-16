<script>
import { convertToGraphQLId } from '~/graphql_shared/utils';
import RunnerTypeAlert from '../components/runner_type_alert.vue';
import RunnerTypeBadge from '../components/runner_type_badge.vue';
import RunnerUpdateForm from '../components/runner_update_form.vue';
import { I18N_DETAILS_TITLE, RUNNER_ENTITY_TYPE } from '../constants';
import getRunnerQuery from '../graphql/get_runner.query.graphql';

export default {
  components: {
    RunnerTypeAlert,
    RunnerTypeBadge,
    RunnerUpdateForm,
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
      runner: null,
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
  <div>
    <h2 class="page-title">
      {{ sprintf($options.i18n.I18N_DETAILS_TITLE, { runner_id: runnerId }) }}

      <runner-type-badge v-if="runner" :type="runner.runnerType" />
    </h2>

    <runner-type-alert v-if="runner" :type="runner.runnerType" />

    <runner-update-form :runner="runner" class="gl-my-5" />
  </div>
</template>
