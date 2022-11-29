<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { GROUP_MODAL_ALERT_BODY } from '../constants';

const SHARE_GROUP_LINK =
  'https://docs.gitlab.com/ee/user/group/manage.html#share-a-group-with-another-group';

export default {
  SHARE_GROUP_LINK,
  name: 'InviteGroupNotification',
  components: { GlAlert, GlSprintf, GlLink },
  inject: ['freeUsersLimit'],
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  i18n: {
    body: GROUP_MODAL_ALERT_BODY,
  },
};
</script>

<template>
  <gl-alert variant="warning" :dismissible="false">
    <gl-sprintf :message="$options.i18n.body">
      <template #link="{ content }">
        <gl-link :href="$options.SHARE_GROUP_LINK" target="_blank" class="gl-label-link">{{
          content
        }}</gl-link>
      </template>

      <template #count>{{ freeUsersLimit }}</template>
    </gl-sprintf>
  </gl-alert>
</template>
