<script>
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import Prompt from '../prompt.vue';

export default {
  name: 'CodeOutput',
  components: {
    CodeBlockHighlighted,
    Prompt,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: 0,
    },
    type: {
      type: String,
      required: true,
    },
    rawCode: {
      type: String,
      required: true,
    },
    metadata: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
  computed: {
    code() {
      return this.rawCode;
    },
    promptType() {
      const type = this.type.split('put')[0];

      return type.charAt(0).toUpperCase() + type.slice(1);
    },
    maxHeight() {
      return this.metadata.scrolled ? '20rem' : 'initial';
    },
  },
};
</script>

<template>
  <div :class="type">
    <prompt :type="promptType" :count="count" />
    <code-block-highlighted
      language="python"
      :code="code"
      :max-height="maxHeight"
      class="gl-border !gl-p-4"
    />
  </div>
</template>
