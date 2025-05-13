<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import VueRouter from 'vue-router';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { visitUrl } from '~/lib/utils/url_utility';

import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import runnerQuery from '../graphql/show/runner.query.graphql';

import { JOBS_ROUTE_PATH, I18N_DETAILS, I18N_JOBS, I18N_FETCH_ERROR } from '../constants';
import { formatJobCount } from '../utils';
import { captureException } from '../sentry_utils';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

import RunnerHeader from './runner_header.vue';
import RunnerHeaderActions from './runner_header_actions.vue';
import RunnerDetails from './runner_details.vue';
import RunnerJobs from './runner_jobs.vue';

const ROUTE_DETAILS = 'details';
const ROUTE_JOBS = 'jobs';

const routes = [
  {
    path: '/',
    name: ROUTE_DETAILS,
    component: RunnerDetails,
  },
  {
    path: JOBS_ROUTE_PATH,
    name: ROUTE_JOBS,
    component: RunnerJobs,
  },
  { path: '*', redirect: { name: ROUTE_DETAILS } },
];

export default {
  name: 'RunnerDetailsTabs',
  components: {
    GlBadge,
    GlTabs,
    GlTab,
    HelpPopover,
    RunnerHeader,
    RunnerHeaderActions,
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
  computed: {
    jobCount() {
      return formatJobCount(this.runner?.jobCount);
    },
    tabIndex() {
      return routes.findIndex(({ name }) => name === this.$route.name);
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
    goTo(name) {
      if (this.$route.name !== name) {
        this.$router.push({ name });
      }
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
        <runner-header-actions :runner="runner" :edit-path="editPath" @deleted="onDeleted" />
      </template>
    </runner-header>

    <gl-tabs :value="tabIndex">
      <gl-tab @click="goTo($options.ROUTE_DETAILS)">
        <template #title>{{ $options.I18N_DETAILS }}</template>
      </gl-tab>
      <gl-tab @click="goTo($options.ROUTE_JOBS)">
        <template #title>
          {{ $options.I18N_JOBS }}
          <gl-badge v-if="jobCount" data-testid="job-count-badge" class="gl-tab-counter-badge">
            {{ jobCount }}
          </gl-badge>
          <help-popover v-if="showAccessHelp" class="gl-ml-3">
            {{ s__('Runners|Jobs in projects you have access to.') }}
          </help-popover>
        </template>
      </gl-tab>

      <router-view :runner-id="runnerId" :runner="runner" />
    </gl-tabs>
  </div>
</template>
