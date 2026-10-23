<script>
import { isObject, isString } from 'lodash-es';
import { GlAvatar, GlAvatarsInline, GlAvatarLink, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'AssigneeAvatars',
  components: {
    GlAvatar,
    GlAvatarsInline,
    GlAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    nodes: {
      type: Array,
      required: true,
      validator: (nodes) => nodes.every((node) => isObject(node) && isString(node.name)),
    },
  },
  computed: {
    badgeSrOnlyText() {
      return n__(
        '%d additional assignee',
        '%d additional assignees',
        this.nodes.length - this.$options.maxVisible,
      );
    },
  },
  avatarSize: 24,
  maxVisible: 2,
};
</script>
<template>
  <gl-avatars-inline
    :avatars="nodes"
    :avatar-size="$options.avatarSize"
    :max-visible="$options.maxVisible"
    :badge-sr-only-text="badgeSrOnlyText"
    collapsed
  >
    <template #avatar="{ avatar }">
      <gl-avatar-link v-gl-tooltip target="_blank" :href="avatar.webUrl" :title="avatar.name">
        <gl-avatar :src="avatar.avatarUrl" :size="$options.avatarSize" />
      </gl-avatar-link>
    </template>
  </gl-avatars-inline>
</template>
