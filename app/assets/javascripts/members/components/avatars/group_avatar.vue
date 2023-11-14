<script>
import { GlAvatarLink, GlAvatarLabeled, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import PrivateIcon from '../icons/private_icon.vue';
import { AVATAR_SIZE } from '../../constants';

export default {
  name: 'GroupAvatar',
  components: { GlAvatarLink, GlAvatarLabeled, PrivateIcon },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    private: __('Private'),
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    group() {
      return this.member.sharedWithGroup;
    },
    isPrivate() {
      return this.member.isSharedWithGroupPrivate;
    },
    avatarLabeledProps() {
      const label = this.isPrivate ? this.$options.i18n.private : this.group.fullName;

      return {
        label,
        src: this.group.avatarUrl,
        alt: label,
        size: AVATAR_SIZE,
        entityName: this.isPrivate ? this.$options.i18n.private : this.group.name,
        entityId: this.group.id,
      };
    },
  },
};
</script>

<template>
  <div v-if="isPrivate">
    <gl-avatar-labeled v-bind="avatarLabeledProps">
      <template #meta>
        <div class="gl-p-1">
          <private-icon />
        </div>
      </template>
    </gl-avatar-labeled>
  </div>
  <gl-avatar-link v-else :href="group.webUrl">
    <gl-avatar-labeled v-bind="avatarLabeledProps" />
  </gl-avatar-link>
</template>
