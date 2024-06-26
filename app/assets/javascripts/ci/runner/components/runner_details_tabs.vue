<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import VueRouter from 'vue-router';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { JOBS_ROUTE_PATH, I18N_DETAILS, I18N_JOBS } from '../constants';
import { formatJobCount } from '../utils';
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
  },
  router: new VueRouter({
    routes,
  }),
  props: {
    runner: {
      type: Object,
      required: false,
      default: null,
    },
    showAccessHelp: {
      type: Boolean,
      required: false,
      default: false,
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

    <router-view v-if="runner" :runner="runner" />
  </gl-tabs>
</template>
