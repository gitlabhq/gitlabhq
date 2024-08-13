<script>
import { GlAvatar, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'ProjectItem',
  components: {
    GlAvatar,
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
    <gl-avatar
      :alt="name"
      :entity-name="name"
      :size="32"
      shape="rect"
      :src="data.avatarUrl"
      fallback-on-error
    />
    <span class="gl-flex gl-max-w-30 gl-grow gl-flex-col">
      <span class="gl-font-bold">{{ name }}</span>
      <span class="gl-text-gray-600">{{ data.nameWithNamespace }}</span>
    </span>

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
