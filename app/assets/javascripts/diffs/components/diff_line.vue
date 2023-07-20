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
    parsedSast() {
      return (this.line.left ?? this.line.right)?.sast;
    },
    codeQualityLineNumber() {
      return this.parsedCodeQuality[0]?.line;
    },
    sastLineNumber() {
      return this.parsedSast[0]?.line;
    },
  },
  methods: {
    hideInlineFindings() {
      this.$emit(
        'hideInlineFindings',
        this.codeQualityLineNumber ? this.codeQualityLineNumber : this.sastLineNumber,
      );
    },
  },
};
</script>

<template>
  <inline-findings
    :code-quality="parsedCodeQuality"
    :sast="parsedSast"
    @hideInlineFindings="hideInlineFindings"
  />
</template>
