<script>
import { GlAvatarLabeled, GlBadge, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { truncate } from '~/lib/utils/text_utility';
import { USER_AVATAR_SIZE, LENGTH_OF_USER_NOTE_TOOLTIP } from '../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatarLabeled,
    GlBadge,
    GlIcon,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    adminUserPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    adminUserHref() {
      return this.adminUserPath.replace('id', this.user.username);
    },
    adminUserMailto() {
      // NOTE: 'mailto:' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `mailto:${this.user.email}`;
    },
    userNoteShort() {
      return truncate(this.user.note, LENGTH_OF_USER_NOTE_TOOLTIP);
    },
  },
  USER_AVATAR_SIZE,
};
</script>

<template>
  <div
    v-if="user"
    class="js-user-link gl-display-inline-block"
    :data-user-id="user.id"
    :data-username="user.username"
  >
    <gl-avatar-labeled
      :size="$options.USER_AVATAR_SIZE"
      :src="user.avatarUrl"
      :label="user.name"
      :sub-label="user.email"
      :label-link="adminUserHref"
      :sub-label-link="adminUserMailto"
    >
      <template #meta>
        <div v-if="user.note" class="gl-text-gray-500 gl-p-1">
          <gl-icon v-gl-tooltip="userNoteShort" name="document" />
        </div>
        <div v-for="(badge, idx) in user.badges" :key="idx" class="gl-p-1">
          <gl-badge class="gl-display-flex!" size="sm" :variant="badge.variant">{{
            badge.text
          }}</gl-badge>
        </div>
      </template>
    </gl-avatar-labeled>
  </div>
</template>
