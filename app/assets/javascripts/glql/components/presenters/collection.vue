<script>
import { GlIntersperse } from '@gitlab/ui';
import NullPresenter from './null.vue';

export default {
  name: 'CollectionPresenter',
  components: {
    NullPresenter,
    GlIntersperse,
    // Lazy load field presenter to avoid circular dependency
    FieldPresenter: () => import('./field.vue'),
  },
  props: {
    data: {
      required: true,
      type: Object,
      validator: ({ nodes }) => Array.isArray(nodes),
    },
  },
};
</script>
<template>
  <gl-intersperse separator=" ">
    <span
      v-for="(field, index) in data.nodes"
      :key="field.id || index"
      class="gl-inline-block gl-pr-2"
    >
      <field-presenter :item="field" />
    </span>
    <null-presenter v-if="!data.nodes.length" />
  </gl-intersperse>
</template>
