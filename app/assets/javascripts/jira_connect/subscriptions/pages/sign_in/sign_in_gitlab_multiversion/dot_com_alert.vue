<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { JIRA_USER_REQUIREMENTS_DOC_LINK } from '~/jira_connect/subscriptions/constants';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  i18n: {
    title: s__('JiraConnect|Are you a Jira administrator?'),
    body: s__(
      'JiraConnect|To complete the setup, you must meet %{linkStart}certain user requirements%{linkEnd} in Jira.',
    ),
  },
  JIRA_USER_REQUIREMENTS_DOC_LINK,
};
</script>

<template>
  <gl-alert variant="warning" :title="$options.i18n.title" :dismissible="false">
    <div>
      <gl-sprintf :message="$options.i18n.body">
        <template #link="{ content }">
          <gl-link :href="$options.JIRA_USER_REQUIREMENTS_DOC_LINK" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </div>
  </gl-alert>
</template>
