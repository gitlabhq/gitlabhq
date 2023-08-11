<script>
import { GlButton } from '@gitlab/ui';
import { NEW_CODE_QUALITY_FINDINGS, NEW_SAST_FINDINGS } from '../i18n';
import DiffInlineFindings from './diff_inline_findings.vue';

export default {
  i18n: {
    newCodeQualityFindings: NEW_CODE_QUALITY_FINDINGS,
    newSastFindings: NEW_SAST_FINDINGS,
  },
  components: { GlButton, DiffInlineFindings },
  props: {
    codeQuality: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div
    data-testid="inline-findings"
    class="gl-relative inline-findings-list gl-border-top-1 gl-border-bottom-1 gl-bg-gray-10 gl-text-black-normal gl-pl-5 gl-pt-4 gl-pb-4"
  >
    <diff-inline-findings
      v-if="codeQuality.length"
      :title="$options.i18n.newCodeQualityFindings"
      :findings="codeQuality"
    />

    <gl-button
      data-testid="inline-findings-close"
      category="tertiary"
      size="small"
      icon="close"
      class="gl-absolute gl-right-2 gl-top-2"
      @click="$emit('hideInlineFindings')"
    />
  </div>
</template>
