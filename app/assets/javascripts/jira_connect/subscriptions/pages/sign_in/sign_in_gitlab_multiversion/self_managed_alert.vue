<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlAlert,
  },
  i18n: {
    title: s__('JiraService|Are you a GitLab administrator?'),
    body: s__(
      "JiraService|Setting up this integration is only possible if you're a GitLab administrator.",
    ),
  },
};
</script>

<template>
  <gl-alert variant="warning" :title="$options.i18n.title" :dismissible="false">
    {{ $options.i18n.body }}
  </gl-alert>
</template>
