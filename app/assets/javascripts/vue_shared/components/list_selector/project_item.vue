<script>
import { GlAvatarLabeled, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'ProjectItem',
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
  },
};
</script>

<template>
  <span class="gl-flex gl-items-center gl-gap-3" @click="$emit('select', name)">
    <gl-avatar-labeled
      class="gl-grow gl-break-all"
      :entity-name="name"
      :label="name"
      :sub-label="data.nameWithNamespace"
      :size="32"
      shape="rect"
      :src="data.avatarUrl"
      fallback-on-error
    />

    <gl-button
      v-if="canDelete"
      v-gl-tooltip="deleteButtonLabel"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      @click="$emit('delete', data.id)"
    />
  </span>
</template>
