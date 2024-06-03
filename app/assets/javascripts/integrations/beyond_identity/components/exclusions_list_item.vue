<script>
import { GlButton, GlIcon, GlAvatar } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ExclusionsListItem',
  components: {
    GlButton,
    GlAvatar,
    GlIcon,
  },
  props: {
    exclusion: {
      type: Object,
      required: true,
    },
  },
  i18n: { remove: __('Remove') },
};
</script>

<template>
  <div
    class="gl-display-flex gl-justify-content-space-between gl-p-4 gl-py-3 gl-pl-7 gl-border-b gl-align-items-center gl-gap-3"
  >
    <gl-icon :name="exclusion.icon" class="gl-text-secondary" />
    <gl-avatar
      :alt="exclusion.name"
      :entity-name="exclusion.name"
      :size="32"
      :src="exclusion.avatarUrl"
      shape="rect"
      fallback-on-error
    />
    <span class="gl-display-flex gl-flex-direction-column gl-flex-grow-1">
      <span class="gl-font-bold">{{ exclusion.name }}</span>
    </span>

    <gl-button
      icon="remove"
      :aria-label="$options.i18n.remove"
      category="tertiary"
      @click="() => $emit('remove')"
    />
  </div>
</template>
