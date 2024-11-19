<script>
import { GlButton, GlIcon, GlAvatar, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

export default {
  name: 'ExclusionsListItem',
  components: {
    GlButton,
    GlAvatar,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    exclusion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    deleteButtonLabel() {
      return sprintf(s__('Integrations|Remove exclusion for %{name}'), {
        name: this.exclusion.name,
      });
    },
  },
};
</script>

<template>
  <div
    class="gl-border-b gl-flex gl-items-center gl-justify-between gl-gap-3 gl-p-4 gl-py-3 gl-pl-7"
  >
    <gl-icon :name="exclusion.icon" variant="subtle" />
    <gl-avatar
      :alt="exclusion.name"
      :entity-name="exclusion.name"
      :size="32"
      :src="exclusion.avatarUrl"
      shape="rect"
      fallback-on-error
    />
    <span class="gl-flex gl-grow gl-flex-col">
      <span class="gl-font-bold">{{ exclusion.name }}</span>
    </span>

    <gl-button
      v-gl-tooltip="s__('Integrations|Remove exclusion')"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      @click="() => $emit('remove')"
    />
  </div>
</template>
