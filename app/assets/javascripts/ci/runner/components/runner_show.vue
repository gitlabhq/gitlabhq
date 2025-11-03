<script>
import { visitUrl } from '~/lib/utils/url_utility';

import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { saveAlertToLocalStorage } from '~/lib/utils/local_storage_alert';
import runnerQuery from '../graphql/show/runner.query.graphql';

import { I18N_FETCH_ERROR } from '../constants';
import { captureException } from '../sentry_utils';

import RunnerHeader from './runner_header.vue';
import RunnerHeaderActions from './runner_header_actions.vue';
import RunnerDetails from './runner_details.vue';

export default {
  name: 'RunnerShow',
  components: {
    RunnerHeader,
    RunnerHeaderActions,
    RunnerDetails,
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
    editPath: {
      type: String,
      required: true,
    },
    showAccessHelp: {
      type: Boolean,
      required: false,
      default: false,
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
    onDeleted({ message }) {
      if (this.runnersPath) {
        saveAlertToLocalStorage({ message, variant: VARIANT_SUCCESS });
        visitUrl(this.runnersPath);
      }
    },
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
        <runner-header-actions :runner="runner" :edit-path="editPath" @deleted="onDeleted" />
      </template>
    </runner-header>

    <runner-details :runner-id="runnerId" :runner="runner" :show-access-help="showAccessHelp" />
  </div>
</template>
