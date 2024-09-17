<script>
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';

export default {
  name: 'DetailsWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      open: true,
    };
  },
};
</script>
<template>
  <node-view-wrapper class="gl-flex">
    <div
      class="details-toggle-icon"
      data-testid="details-toggle-icon"
      :class="{ 'is-open': open }"
      @click="open = !open"
    ></div>
    <node-view-content as="ul" class="details-content" :class="{ 'is-open': open }" dir="auto" />
  </node-view-wrapper>
</template>
