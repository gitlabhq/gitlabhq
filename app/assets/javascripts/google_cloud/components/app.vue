<script>
import { __ } from '~/locale';

import Home from './home.vue';
import IncubationBanner from './incubation_banner.vue';
import ServiceAccountsForm from './service_accounts_form.vue';
import GcpRegionsForm from './gcp_regions_form.vue';
import NoGcpProjects from './errors/no_gcp_projects.vue';
import GcpError from './errors/gcp_error.vue';

const SCREEN_GCP_ERROR = 'gcp_error';
const SCREEN_HOME = 'home';
const SCREEN_NO_GCP_PROJECTS = 'no_gcp_projects';
const SCREEN_SERVICE_ACCOUNTS_FORM = 'service_accounts_form';
const SCREEN_GCP_REGIONS_FORM = 'gcp_regions_form';

export default {
  components: {
    IncubationBanner,
  },
  inheritAttrs: false,
  props: {
    screen: {
      required: true,
      type: String,
    },
  },
  computed: {
    mainComponent() {
      switch (this.screen) {
        case SCREEN_HOME:
          return Home;
        case SCREEN_GCP_ERROR:
          return GcpError;
        case SCREEN_NO_GCP_PROJECTS:
          return NoGcpProjects;
        case SCREEN_SERVICE_ACCOUNTS_FORM:
          return ServiceAccountsForm;
        case SCREEN_GCP_REGIONS_FORM:
          return GcpRegionsForm;
        default:
          throw new Error(__('Unknown screen'));
      }
    },
  },
  methods: {
    feedbackUrl(template) {
      return `https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/meta/-/issues/new?issuable_template=${template}`;
    },
  },
};
</script>

<template>
  <div>
    <incubation-banner
      :share-feedback-url="feedbackUrl('general_feedback')"
      :report-bug-url="feedbackUrl('report_bug')"
      :feature-request-url="feedbackUrl('feature_request')"
    />
    <component :is="mainComponent" v-bind="$attrs" />
  </div>
</template>
