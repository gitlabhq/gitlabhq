<script>
import { GlButton } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    numberOfClosedItems: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    buttonText() {
      const itemText = n__('item', 'items', this.numberOfClosedItems);
      return sprintf(__('Show %{count} closed %{itemText}'), {
        count: this.numberOfClosedItems,
        itemText,
      });
    },
  },
};
</script>

<template>
  <div class="gl-flex">
    <gl-button category="tertiary" variant="confirm" @click="$emit('show-closed')">
      {{ buttonText }}
    </gl-button>
  </div>
</template>
