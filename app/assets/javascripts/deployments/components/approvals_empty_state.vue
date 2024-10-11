<script>
import { GlBanner, GlTableLite, GlBadge } from '@gitlab/ui';
import emptyStateIllustration from '@gitlab/svgs/dist/illustrations/secure-sm.svg';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    UserCalloutDismisser,
    GlBanner,
    GlTableLite,
    GlBadge,
  },
  props: {
    bannerTitle: {
      type: String,
      required: false,
      default: s__('Deployment|Upgrade to get more our of your deployments'),
    },
    buttonText: {
      type: String,
      required: false,
      default: __('Learn more'),
    },
    buttonLink: {
      type: String,
      required: false,
      default: helpPagePath('ci/environments/deployment_approvals'),
    },
    illustration: {
      type: String,
      required: false,
      default: emptyStateIllustration,
    },
  },
  fields: [
    { key: 'approvers', label: s__('DeploymentApprovals|Approvers') },
    { key: 'approvals', label: s__('DeploymentApprovals|Approvals') },
    { key: 'approvedBy', label: s__('DeploymentApprovals|Approved By') },
  ],
  items: [
    { approvers: s__('Deployment|You'), approvals: '0/1' },
    { approvers: s__('Deployment|A colleague'), approvals: '0/1' },
  ],
  i18n: {
    bannerDescription: s__(
      'Deployment|Improve your continuous delivery practices with deployment approvals. Configure rules for required approvals, control which users can deploy to your environments, and collaborate throughout the delivery process.',
    ),
    tableHeader: s__('Deployment|Deployment approvals require a Premium or Ultimate subscription'),
    readyText: s__('Deployment|Ready to use deployment approvals?'),
    premiumTitle: __('GitLab Premium'),
  },
};
</script>
<template>
  <user-callout-dismisser feature-name="deployment_approvals_empty_state">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-banner
        v-if="shouldShowCallout"
        :title="bannerTitle"
        :button-text="buttonText"
        :button-link="buttonLink"
        :svg-path="illustration"
        class="gl-mt-5"
        @close="dismiss"
      >
        <p>{{ $options.i18n.bannerDescription }}</p>

        <div class="gl-border-t gl-border-r gl-border-l gl-mb-5 gl-rounded-base">
          <div class="gl-m-5">
            <slot name="table-header">
              <gl-badge class="gl-mr-2 gl-align-middle" icon="license" variant="tier">{{
                $options.i18n.premiumTitle
              }}</gl-badge>
              <strong class="gl-align-middle">{{ $options.i18n.tableHeader }}</strong>
            </slot>
          </div>
          <gl-table-lite :fields="$options.fields" :items="$options.items" />
        </div>

        <template #actions>
          <slot name="banner-actions">
            <strong class="gl-ml-2 gl-align-middle">{{ $options.i18n.readyText }}</strong>
          </slot>
        </template>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>
