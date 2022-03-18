<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { TYPE_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import RunnerEditButton from '../components/runner_edit_button.vue';
import RunnerPauseButton from '../components/runner_pause_button.vue';
import RunnerHeader from '../components/runner_header.vue';
import RunnerDetails from '../components/runner_details.vue';
import { I18N_FETCH_ERROR } from '../constants';
import runnerQuery from '../graphql/details/runner.query.graphql';
import { captureException } from '../sentry_utils';

export default {
  name: 'AdminRunnerShowApp',
  components: {
    RunnerEditButton,
    RunnerPauseButton,
    RunnerHeader,
    RunnerDetails,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
          id: convertToGraphQLId(TYPE_CI_RUNNER, this.runnerId),
        };
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });

        this.reportToSentry(error);
      },
    },
  },
  computed: {
    canUpdate() {
      return this.runner.userPermissions?.updateRunner;
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
    <runner-header v-if="runner" :runner="runner">
      <template #actions>
        <runner-edit-button v-if="canUpdate && runner.editAdminUrl" :href="runner.editAdminUrl" />
        <runner-pause-button v-if="canUpdate" :runner="runner" />
      </template>
    </runner-header>

    <runner-details :runner="runner" />
  </div>
</template>
