<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlAlert },
  props: {
    error: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: __('Google Cloud project misconfigured'),
    description: __(
      'GitLab and Google Cloud configuration seems to be incomplete. This probably can be fixed by your GitLab administration team. You may share these logs with them:',
    ),
  },
};
</script>

<template>
  <gl-alert :dismissible="false" variant="warning" :title="$options.i18n.title">
    {{ $options.i18n.description }}
    <blockquote>
      <code>{{ error }}</code>
    </blockquote>
  </gl-alert>
</template>
