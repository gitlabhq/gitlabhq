<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'DeployKeyItem',
  components: { GlButton, GlIcon },
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
  data() {
    const { title, owner, id } = this.data;
    return {
      deleteButtonLabel: sprintf(__('Delete %{name}'), { name: title }),
      title,
      owner,
      id,
    };
  },
};
</script>

<template>
  <span
    class="gl-display-flex gl-align-items-center gl-gap-3"
    data-testid="deploy-key-wrapper"
    @click="$emit('select', id)"
  >
    <gl-icon name="key" />
    <span class="gl-display-flex gl-flex-direction-column gl-flex-grow-1">
      <span class="gl-font-weight-bold">{{ title }}</span>
      <span class="gl-text-gray-600">@{{ owner }}</span>
    </span>

    <gl-button
      v-if="canDelete"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      @click.stop="$emit('delete', id)"
    />
  </span>
</template>
