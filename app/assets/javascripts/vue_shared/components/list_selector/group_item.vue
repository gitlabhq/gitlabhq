<script>
import { GlAvatar, GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'GroupItem',
  components: {
    GlAvatar,
    GlButton,
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
    fullName() {
      return this.data.fullName;
    },
    name() {
      return this.data.name;
    },
    avatarUrl() {
      return this.data.avatarUrl;
    },
  },
};
</script>

<template>
  <span class="gl-display-flex gl-align-items-center gl-gap-3" @click="$emit('select', name)">
    <gl-avatar :alt="fullName" :size="32" :src="avatarUrl" />
    <span class="gl-display-flex gl-flex-direction-column gl-flex-grow-1">
      <span class="gl-font-weight-bold">{{ fullName }}</span>
      <span class="gl-text-gray-600">@{{ name }}</span>
    </span>

    <gl-button
      v-if="canDelete"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      @click="$emit('delete', name)"
    />
  </span>
</template>
