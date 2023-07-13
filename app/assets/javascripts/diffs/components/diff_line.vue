<script>
import DiffCodeQuality from './diff_code_quality.vue';

export default {
  components: {
    DiffCodeQuality,
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
    hideCodeQualityFindings() {
      this.$emit(
        'hideCodeQualityFindings',
        this.codeQualityLineNumber ? this.codeQualityLineNumber : this.sastLineNumber,
      );
    },
  },
};
</script>

<template>
  <diff-code-quality
    :code-quality="parsedCodeQuality"
    :sast="parsedSast"
    @hideCodeQualityFindings="hideCodeQualityFindings"
  />
</template>
