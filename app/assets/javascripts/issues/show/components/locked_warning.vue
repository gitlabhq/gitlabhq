<script>
import { GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

const alertMessage = __(
  'Someone edited the issue at the same time you did. Please check out %{linkStart}the issue%{linkEnd} and make sure your changes will not unintentionally remove theirs.',
);

export default {
  alertMessage,
  components: {
    GlSprintf,
    GlLink,
    GlAlert,
  },
  computed: {
    currentPath() {
      return window.location.pathname;
    },
  },
};
</script>

<template>
  <gl-alert variant="danger" class="gl-mb-5" :dismissible="false">
    <gl-sprintf :message="$options.alertMessage">
      <template #link="{ content }">
        <gl-link :href="currentPath" target="_blank" rel="nofollow">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
