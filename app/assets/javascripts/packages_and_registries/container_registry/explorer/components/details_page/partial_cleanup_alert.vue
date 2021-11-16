<script>
import { GlSprintf, GlAlert, GlLink } from '@gitlab/ui';

import { DELETE_ALERT_TITLE, DELETE_ALERT_LINK_TEXT } from '../../constants/index';

export default {
  components: {
    GlSprintf,
    GlAlert,
    GlLink,
  },
  props: {
    runCleanupPoliciesHelpPagePath: { type: String, required: false, default: '' },
    cleanupPoliciesHelpPagePath: { type: String, required: false, default: '' },
  },
  i18n: {
    DELETE_ALERT_TITLE,
    DELETE_ALERT_LINK_TEXT,
  },
};
</script>

<template>
  <gl-alert variant="warning" :title="$options.i18n.DELETE_ALERT_TITLE" @dismiss="$emit('dismiss')">
    <gl-sprintf :message="$options.i18n.DELETE_ALERT_LINK_TEXT">
      <template #adminLink="{ content }">
        <gl-link data-testid="run-link" :href="runCleanupPoliciesHelpPagePath" target="_blank">{{
          content
        }}</gl-link>
      </template>
      <template #docLink="{ content }">
        <gl-link data-testid="help-link" :href="cleanupPoliciesHelpPagePath" target="_blank">{{
          content
        }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
