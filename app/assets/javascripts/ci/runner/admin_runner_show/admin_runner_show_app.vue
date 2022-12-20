<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import VueRouter from 'vue-router';
import { createAlert, VARIANT_SUCCESS } from '~/flash';
import { TYPE_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { redirectTo } from '~/lib/utils/url_utility';
import { formatJobCount } from '../utils';
import RunnerDeleteButton from '../components/runner_delete_button.vue';
import RunnerEditButton from '../components/runner_edit_button.vue';
import RunnerPauseButton from '../components/runner_pause_button.vue';
import RunnerHeader from '../components/runner_header.vue';
import RunnerDetails from '../components/runner_details.vue';
import RunnerJobs from '../components/runner_jobs.vue';
import { I18N_DETAILS, I18N_JOBS, I18N_FETCH_ERROR } from '../constants';
import runnerQuery from '../graphql/show/runner.query.graphql';
import { captureException } from '../sentry_utils';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

const ROUTE_DETAILS = 'details';
const ROUTE_JOBS = 'jobs';

const routes = [
  {
    path: '/',
    name: ROUTE_DETAILS,
    component: RunnerDetails,
  },
  {
    path: '/jobs',
    name: ROUTE_JOBS,
    component: RunnerJobs,
  },
  { path: '*', redirect: { name: ROUTE_DETAILS } },
];

export default {
  name: 'AdminRunnerShowApp',
  components: {
    GlBadge,
    GlTabs,
    GlTab,
    RunnerDeleteButton,
    RunnerEditButton,
    RunnerPauseButton,
    RunnerHeader,
  },
  router: new VueRouter({
    routes,
  }),
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
    canDelete() {
      return this.runner.userPermissions?.deleteRunner;
    },
    jobCount() {
      return formatJobCount(this.runner?.jobCount);
    },
    tabIndex() {
      return routes.findIndex(({ name }) => name === this.$route.name);
    },
  },
  errorCaptured(error) {
    this.reportToSentry(error);
  },
  methods: {
    goTo(name) {
      this.$router.push({ name });
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
    onDeleted({ message }) {
      saveAlertToLocalStorage({ message, variant: VARIANT_SUCCESS });
      redirectTo(this.runnersPath);
    },
  },
  ROUTE_DETAILS,
  ROUTE_JOBS,
  I18N_DETAILS,
  I18N_JOBS,
};
</script>
<template>
  <div>
    <runner-header v-if="runner" :runner="runner">
      <template #actions>
        <runner-edit-button v-if="canUpdate && runner.editAdminUrl" :href="runner.editAdminUrl" />
        <runner-pause-button v-if="canUpdate" :runner="runner" />
        <runner-delete-button v-if="canDelete" :runner="runner" @deleted="onDeleted" />
      </template>
    </runner-header>

    <gl-tabs :value="tabIndex">
      <gl-tab @click="goTo($options.ROUTE_DETAILS)">
        <template #title>{{ $options.I18N_DETAILS }}</template>
      </gl-tab>
      <gl-tab @click="goTo($options.ROUTE_JOBS)">
        <template #title>
          {{ $options.I18N_JOBS }}
          <gl-badge
            v-if="jobCount"
            data-testid="job-count-badge"
            class="gl-tab-counter-badge"
            size="sm"
          >
            {{ jobCount }}
          </gl-badge>
        </template>
      </gl-tab>

      <router-view v-if="runner" :runner="runner" />
    </gl-tabs>
  </div>
</template>
