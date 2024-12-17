<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';

import RunnerHeader from '../components/runner_header.vue';
import RunnerHeaderActions from '../components/runner_header_actions.vue';
import RunnerDetailsTabs from '../components/runner_details_tabs.vue';

import { I18N_FETCH_ERROR } from '../constants';
import runnerQuery from '../graphql/show/runner.query.graphql';
import { captureException } from '../sentry_utils';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'AdminRunnerShowApp',
  components: {
    RunnerHeader,
    RunnerHeaderActions,
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
  methods: {
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
    onDeleted({ message }) {
      saveAlertToLocalStorage({ message, variant: VARIANT_SUCCESS });
      visitUrl(this.runnersPath);
    },
  },
};
</script>
<template>
  <div>
    <runner-header v-if="runner" :runner="runner">
      <template #actions>
        <runner-header-actions
          :runner="runner"
          :edit-path="runner.editAdminUrl"
          @deleted="onDeleted"
        />
      </template>
    </runner-header>
    <runner-details-tabs v-if="runner" :runner="runner" />
  </div>
</template>
