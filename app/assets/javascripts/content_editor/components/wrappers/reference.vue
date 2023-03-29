<script>
import { NodeViewWrapper } from '@tiptap/vue-2';

export default {
  name: 'DetailsWrapper',
  components: {
    NodeViewWrapper,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <node-view-wrapper class="gl-display-inline-block">
    <span v-if="node.attrs.referenceType === 'command'">{{ node.attrs.text }}</span>
    <a v-else href="#" @click.prevent.stop>{{ node.attrs.text }}</a>
  </node-view-wrapper>
</template>
