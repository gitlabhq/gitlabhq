<script>
import InlineFindings from './inline_findings.vue';

export default {
  components: {
    InlineFindings,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
  },
  computed: {
    parsedCodeQuality() {
      return (this.line.left ?? this.line.right)?.codequality;
    },
    codeQualityLineNumber() {
      return this.parsedCodeQuality[0]?.line;
    },
  },
  methods: {
    hideInlineFindings() {
      this.$emit('hideInlineFindings', this.codeQualityLineNumber);
    },
  },
};
</script>

<template>
  <inline-findings :code-quality="parsedCodeQuality" @hideInlineFindings="hideInlineFindings" />
</template>
