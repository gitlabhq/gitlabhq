<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';

export default {
  name: 'InviteGroupNotification',
  components: { GlAlert, GlSprintf, GlLink },
  inject: ['freeUsersLimit'],
  props: {
    name: {
      type: String,
      required: true,
    },
    notificationText: {
      type: String,
      required: true,
    },
    notificationLink: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-alert variant="warning" :dismissible="false">
    <gl-sprintf :message="notificationText">
      <template #link="{ content }">
        <gl-link :href="notificationLink" target="_blank" class="gl-label-link">{{
          content
        }}</gl-link>
      </template>

      <template #count>{{ freeUsersLimit }}</template>
    </gl-sprintf>
  </gl-alert>
</template>
