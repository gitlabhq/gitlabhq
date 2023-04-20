<script>
import { GlButton } from '@gitlab/ui';
import { NEW_CODE_QUALITY_FINDINGS } from '../i18n';
import DiffCodeQualityItem from './diff_code_quality_item.vue';

export default {
  i18n: {
    newFindings: NEW_CODE_QUALITY_FINDINGS,
  },
  components: { GlButton, DiffCodeQualityItem },
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
    data-testid="diff-codequality"
    class="gl-relative codequality-findings-list gl-border-top-1 gl-border-bottom-1 gl-bg-gray-10 gl-text-black-normal gl-pl-5 gl-pt-4 gl-pb-4"
  >
    <h4
      data-testid="diff-codequality-findings-heading"
      class="gl-mt-0 gl-mb-0 gl-font-base gl-font-regular"
    >
      {{ $options.i18n.newFindings }}
    </h4>
    <ul class="gl-list-style-none gl-mb-0 gl-p-0">
      <diff-code-quality-item
        v-for="finding in codeQuality"
        :key="finding.description"
        :finding="finding"
      />
    </ul>
    <gl-button
      data-testid="diff-codequality-close"
      category="tertiary"
      size="small"
      icon="close"
      class="gl-absolute gl-right-2 gl-top-2"
      @click="$emit('hideCodeQualityFindings')"
    />
  </div>
</template>
