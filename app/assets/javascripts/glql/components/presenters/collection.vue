<script>
import { GlIntersperse } from '@gitlab/ui';
import NullPresenter from './null.vue';

export default {
  name: 'CollectionPresenter',
  components: {
    NullPresenter,
    GlIntersperse,
  },
  inject: ['presenter'],
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
    <span v-for="(field, index) in data.nodes" :key="index" class="gl-inline-block gl-pr-2">
      <component :is="presenter.forField(field)" />
    </span>
    <null-presenter v-if="!data.nodes.length" />
  </gl-intersperse>
</template>
