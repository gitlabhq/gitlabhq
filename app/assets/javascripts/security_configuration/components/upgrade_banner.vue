<script>
import { GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlBanner,
  },
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
        'SecurityConfiguration|More scan types, including Container Scanning, DAST, Dependency Scanning, Fuzzing, and Licence Compliance',
      ),
    ],
    buttonText: s__('SecurityConfiguration|Upgrade or start a free trial'),
  },
};
</script>

<template>
  <gl-banner
    :title="$options.i18n.title"
    :button-text="$options.i18n.buttonText"
    :button-link="upgradePath"
    variant="introduction"
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
