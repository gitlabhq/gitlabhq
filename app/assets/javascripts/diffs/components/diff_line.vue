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
    codeQualityLineNumber() {
      return this.parsedCodeQuality[0].line;
    },
  },
  methods: {
    hideCodeQualityFindings() {
      this.$emit('hideCodeQualityFindings', this.codeQualityLineNumber);
    },
  },
};
</script>

<template>
  <diff-code-quality
    :code-quality="parsedCodeQuality"
    @hideCodeQualityFindings="hideCodeQualityFindings"
  />
</template>
