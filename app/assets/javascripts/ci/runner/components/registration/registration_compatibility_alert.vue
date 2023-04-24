<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { CHANGELOG_URL } from '../../constants';

export default {
  name: 'RegistrationCompatibilityAlert',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  CHANGELOG_URL,
  i18n: {
    title: s__(
      'Runners|This registration process is only supported in GitLab Runner 15.10 or later',
    ),
    message: s__(
      'Runners|This registration process is not supported in GitLab Runner 15.9 or earlier and only available as an experimental feature in GitLab Runner 15.10 and 15.11. You should upgrade to %{linkStart}GitLab Runner 16.0%{linkEnd} or later to use a stable version of this registration process.',
    ),
  },
};
</script>

<template>
  <gl-alert class="gl-mb-4" variant="warning" :dismissible="false" :title="$options.i18n.title">
    <gl-sprintf :message="$options.i18n.message">
      <template #link="{ content }">
        <gl-link :href="$options.CHANGELOG_URL" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
