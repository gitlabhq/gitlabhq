<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'BrowserSupportAlert',
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  i18n: {
    title: s__('JiraConnect|Your browser is not supported'),
    body: s__(
      'JiraConnect|You must use a %{linkStart}supported browser%{linkEnd} to use the GitLab for Jira app.',
    ),
  },
  DOCS_LINK_URL: helpPagePath('install/requirements', { anchor: 'supported-web-browsers' }),
};
</script>

<template>
  <gl-alert variant="danger" :title="$options.i18n.title" :dismissible="false">
    <gl-sprintf :message="$options.i18n.body">
      <template #link="{ content }">
        <gl-link :href="$options.DOCS_LINK_URL" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
