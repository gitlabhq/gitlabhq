<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';

export default {
  name: 'IntegrationsHelpText',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    message: {
      type: String,
      required: true,
    },
    messageUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="message">
      <template #link="{ content }">
        <gl-link :href="messageUrl" target="_blank">
          {{ content }}
          <gl-icon name="external-link" class="gl-align-middle" :size="12" />
        </gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
