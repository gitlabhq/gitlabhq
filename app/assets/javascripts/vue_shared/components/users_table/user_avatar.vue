<script>
import { GlAvatarLabeled, GlBadge, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { truncate } from '~/lib/utils/text_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { USER_AVATAR_SIZE, LENGTH_OF_USER_NOTE_TOOLTIP } from './constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatarLabeled,
    GlBadge,
    GlIcon,
  },
  mixins: [glFeatureFlagsMixin()],
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
    subLabel() {
      if (this.user.email) {
        return {
          label: this.user.email,
          link: `mailto:${this.user.email}`,
        };
      }

      return {
        label: `@${this.user.username}`,
      };
    },
    adminUserHref() {
      return this.adminUserPath.replace('id', this.user.username);
    },
    userNoteShort() {
      return truncate(this.user.note, LENGTH_OF_USER_NOTE_TOOLTIP);
    },
    userId() {
      return getIdFromGraphQLId(this.user.id);
    },
  },
  USER_AVATAR_SIZE,
};
</script>

<template>
  <div
    v-if="user"
    class="js-user-popover gl-inline-block"
    :data-user-id="userId"
    :data-username="user.username"
  >
    <gl-avatar-labeled
      :size="$options.USER_AVATAR_SIZE"
      :src="user.avatarUrl"
      :label="user.name"
      :sub-label="subLabel.label"
      :label-link="adminUserHref"
      :sub-label-link="subLabel.link"
    >
      <template #meta>
        <div v-if="user.note" class="gl-p-1 gl-text-subtle">
          <gl-icon v-gl-tooltip="userNoteShort" name="document" />
        </div>
        <div
          v-for="(badge, idx) in user.badges"
          :key="idx"
          class="gl-p-1"
          :class="{ 'gl-pb-0': glFeatures.simplifiedBadges }"
        >
          <gl-badge class="!gl-flex" :variant="badge.variant">{{ badge.text }}</gl-badge>
        </div>
      </template>
    </gl-avatar-labeled>
  </div>
</template>
