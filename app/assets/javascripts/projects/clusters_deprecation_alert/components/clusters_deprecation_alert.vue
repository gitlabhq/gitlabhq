<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  inject: ['message'],
  docsLink: helpPagePath('user/infrastructure/clusters/migrate_to_gitlab_agent.md'),
  deprecationEpic: 'https://gitlab.com/groups/gitlab-org/configure/-/epics/8',
};
</script>
<template>
  <gl-alert :dismissible="false" variant="warning" class="gl-mt-5">
    <gl-sprintf :message="message">
      <template #link="{ content }">
        <gl-link :href="$options.docsLink">{{ content }}</gl-link>
      </template>
      <template #deprecationLink="{ content }">
        <gl-link :href="$options.deprecationEpic">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
