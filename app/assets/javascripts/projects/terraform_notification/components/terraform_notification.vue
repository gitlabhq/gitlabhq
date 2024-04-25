<script>
import { GlBanner } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { EVENT_LABEL, DISMISS_EVENT, CLICK_EVENT } from '../constants';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL });

export default {
  name: 'TerraformNotification',
  i18n: {
    title: s__('TerraformBanner|Using Terraform? Try the GitLab Managed Terraform State'),
    description: s__(
      'TerraformBanner|The GitLab managed Terraform state backend can store your Terraform state easily and securely, and spares you from setting up additional remote resources. Its features include: versioning, encryption of the state file both in transit and at rest, locking, and remote Terraform plan/apply execution.',
    ),
    buttonText: s__("TerraformBanner|Learn more about GitLab's Backend State"),
  },
  components: {
    GlBanner,
    UserCalloutDismisser,
  },
  mixins: [trackingMixin],
  inject: ['terraformImagePath'],
  computed: {
    docsUrl() {
      return helpPagePath('user/infrastructure/iac/terraform_state.md');
    },
  },
  methods: {
    handleClose() {
      this.track(DISMISS_EVENT);
      this.$refs.calloutDismisser.dismiss();
    },
    buttonClick() {
      this.track(CLICK_EVENT);
    },
  },
};
</script>
<template>
  <user-callout-dismisser ref="calloutDismisser" feature-name="terraform_notification_dismissed">
    <template #default="{ shouldShowCallout }">
      <div v-if="shouldShowCallout" class="gl-pt-5">
        <gl-banner
          :title="$options.i18n.title"
          :button-text="$options.i18n.buttonText"
          :button-link="docsUrl"
          :svg-path="terraformImagePath"
          variant="promotion"
          @primary="buttonClick"
          @close="handleClose"
        >
          <p>{{ $options.i18n.description }}</p>
        </gl-banner>
      </div>
    </template>
  </user-callout-dismisser>
</template>
