<script>
import { GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlBanner,
  },
  inject: ['upgradePath'],
  i18n: {
    title: s__('SecurityConfiguration|Secure your project with Ultimate'),
    bodyStart: s__(
      `SecurityConfiguration|GitLab Ultimate checks your application for security vulnerabilities
      that may lead to unauthorized access, data leaks, and denial of service
      attacks. Its features include:`,
    ),
    bodyListItems: [
      s__('SecurityConfiguration|Vulnerability details and statistics in the merge request.'),
      s__('SecurityConfiguration|High-level vulnerability statistics across projects and groups.'),
      s__('SecurityConfiguration|Runtime security metrics for application environments.'),
    ],
    bodyEnd: s__(
      'SecurityConfiguration|With the information provided, you can immediately begin risk analysis and remediation within GitLab.',
    ),
    buttonText: s__('SecurityConfiguration|Upgrade or start a free trial'),
  },
};
</script>

<template>
  <gl-banner
    :title="$options.i18n.title"
    :button-text="$options.i18n.buttonText"
    :button-link="upgradePath"
    v-on="$listeners"
  >
    <p>{{ $options.i18n.bodyStart }}</p>
    <ul>
      <li v-for="bodyListItem in $options.i18n.bodyListItems" :key="bodyListItem">
        {{ bodyListItem }}
      </li>
    </ul>
    <p>{{ $options.i18n.bodyEnd }}</p>
  </gl-banner>
</template>
