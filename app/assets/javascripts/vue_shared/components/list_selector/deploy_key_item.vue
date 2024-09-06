<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'DeployKeyItem',
  components: { GlButton, GlIcon },
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
      return sprintf(__('Delete %{name}'), { name: this.title });
    },
    title() {
      return this.data.title;
    },
    username() {
      return this.data.user?.name;
    },
    id() {
      return this.data.id;
    },
  },
};
</script>

<template>
  <span class="gl-flex gl-items-center gl-gap-3" data-testid="deploy-key-wrapper">
    <gl-icon name="key" />
    <span class="gl-flex gl-grow gl-flex-col">
      <span class="gl-font-bold">{{ title }}</span>
      <span class="gl-text-gray-600">@{{ username }}</span>
    </span>

    <gl-button
      v-if="canDelete"
      v-gl-tooltip="deleteButtonLabel"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      @click.stop="$emit('delete', id)"
    />
  </span>
</template>
