<script>
import { GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export const SECURITY_UPGRADE_BANNER = 'security_upgrade_banner';
export const UPGRADE_OR_FREE_TRIAL = 'upgrade_or_free_trial';

export default {
  components: {
    GlBanner,
  },
  mixins: [Tracking.mixin({ property: SECURITY_UPGRADE_BANNER })],
  inject: ['upgradePath'],
  i18n: {
    title: s__('SecurityConfiguration|Secure your project'),
    bodyStart: s__(
      `SecurityConfiguration|Immediately begin risk analysis and remediation with application security features. Start with SAST and Secret Detection, available to all plans. Upgrade to Ultimate to get all features, including:`,
    ),
    bodyListItems: [
      s__('SecurityConfiguration|Vulnerability details and statistics in the merge request'),
      s__('SecurityConfiguration|High-level vulnerability statistics across projects and groups'),
      s__('SecurityConfiguration|Runtime security metrics for application environments'),
      s__(
        'SecurityConfiguration|More scan types, including DAST, Dependency Scanning, Fuzzing, and Licence Compliance',
      ),
    ],
    buttonText: s__('SecurityConfiguration|Upgrade or start a free trial'),
  },
  mounted() {
    this.track('render', { label: SECURITY_UPGRADE_BANNER });
  },
  methods: {
    bannerClosed() {
      this.track('dismiss_banner', { label: SECURITY_UPGRADE_BANNER });
    },
    bannerButtonClicked() {
      this.track('click_button', { label: UPGRADE_OR_FREE_TRIAL });
    },
  },
};
</script>

<template>
  <gl-banner
    :title="$options.i18n.title"
    :button-text="$options.i18n.buttonText"
    :button-link="upgradePath"
    variant="introduction"
    @close="bannerClosed"
    @primary="bannerButtonClicked"
    v-on="$listeners"
  >
    <p>{{ $options.i18n.bodyStart }}</p>
    <ul class="gl-pl-6">
      <li v-for="bodyListItem in $options.i18n.bodyListItems" :key="bodyListItem">
        {{ bodyListItem }}
      </li>
    </ul>
  </gl-banner>
</template>
