<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import IncubationBanner from './incubation_banner.vue';
import ServiceAccounts from './service_accounts.vue';

export default {
  components: { GlTab, GlTabs, IncubationBanner, ServiceAccounts },
  props: {
    serviceAccounts: {
      type: Array,
      required: true,
    },
    createServiceAccountUrl: {
      type: String,
      required: true,
    },
    emptyIllustrationUrl: {
      type: String,
      required: true,
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
    <gl-tabs>
      <gl-tab :title="__('Configuration')">
        <service-accounts
          class="gl-mx-3"
          :list="serviceAccounts"
          :create-url="createServiceAccountUrl"
          :empty-illustration-url="emptyIllustrationUrl"
        />
      </gl-tab>
      <gl-tab :title="__('Deployments')" disabled />
      <gl-tab :title="__('Services')" disabled />
    </gl-tabs>
  </div>
</template>
