<script>
import { GlAvatarLabeled, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'UserItem',
  components: {
    GlAvatarLabeled,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    deleteButtonLabel() {
      return sprintf(__('Delete %{name}'), { name: this.name });
    },
    name() {
      return this.data.name;
    },
    username() {
      return this.data.username;
    },
    avatarUrl() {
      return this.data.avatarUrl;
    },
  },
};
</script>

<template>
  <span class="gl-flex gl-items-center gl-gap-3">
    <gl-avatar-labeled
      class="gl-grow gl-break-all"
      :entity-name="name"
      :label="name"
      :sub-label="`@${username}`"
      :size="32"
      :src="avatarUrl"
      fallback-on-error
    />

    <gl-button
      v-if="canDelete"
      v-gl-tooltip="deleteButtonLabel"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      data-testid="delete-user-btn"
      @click="$emit('delete', data.id)"
    />
  </span>
</template>
