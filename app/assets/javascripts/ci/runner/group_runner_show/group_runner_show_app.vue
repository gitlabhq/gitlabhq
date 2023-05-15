<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated

import RunnerDeleteButton from '../components/runner_delete_button.vue';
import RunnerEditButton from '../components/runner_edit_button.vue';
import RunnerPauseButton from '../components/runner_pause_button.vue';
import RunnerHeader from '../components/runner_header.vue';
import RunnerDetailsTabs from '../components/runner_details_tabs.vue';

import { I18N_FETCH_ERROR } from '../constants';
import runnerQuery from '../graphql/show/runner.query.graphql';
import { captureException } from '../sentry_utils';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'GroupRunnerShowApp',
  components: {
    RunnerDeleteButton,
    RunnerEditButton,
    RunnerPauseButton,
    RunnerHeader,
    RunnerDetailsTabs,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
      type: String,
      required: true,
    },
    editGroupRunnerPath: {
      type: String,
      required: false,
      default: null,
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
  computed: {
    canUpdate() {
      return this.runner.userPermissions?.updateRunner;
    },
    canDelete() {
      return this.runner.userPermissions?.deleteRunner;
    },
  },
  errorCaptured(error) {
    this.reportToSentry(error);
  },
  methods: {
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
    onDeleted({ message }) {
      saveAlertToLocalStorage({ message, variant: VARIANT_SUCCESS });
      redirectTo(this.runnersPath); // eslint-disable-line import/no-deprecated
    },
  },
};
</script>
<template>
  <div>
    <runner-header v-if="runner" :runner="runner">
      <template #actions>
        <runner-edit-button v-if="canUpdate && editGroupRunnerPath" :href="editGroupRunnerPath" />
        <runner-pause-button v-if="canUpdate" :runner="runner" />
        <runner-delete-button v-if="canDelete" :runner="runner" @deleted="onDeleted" />
      </template>
    </runner-header>

    <runner-details-tabs :runner="runner" :show-access-help="true" />
  </div>
</template>
