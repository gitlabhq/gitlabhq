<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlAlert, GlButton },
  i18n: {
    title: __('Google Cloud project required'),
    description: __(
      'You do not have any Google Cloud projects. Please create a Google Cloud project and then reload this page.',
    ),
    createLabel: __('Create Google Cloud project'),
  },
};
</script>

<template>
  <gl-alert :dismissible="false" variant="warning" :title="$options.i18n.title">
    {{ $options.i18n.description }}
    <template #actions>
      <gl-button href="https://console.cloud.google.com/projectcreate" target="_blank">
        {{ $options.i18n.createLabel }}
      </gl-button>
    </template>
  </gl-alert>
</template>
