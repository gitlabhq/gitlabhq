<script>
import DiffInlineFindingsItem from './diff_inline_findings_item.vue';

export default {
  components: { DiffInlineFindingsItem },
  props: {
    title: {
      type: String,
      required: true,
    },
    findings: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <h4 data-testid="diff-inline-findings-heading" class="gl-my-0 gl-font-base gl-font-regular">
      {{ title }}
    </h4>
    <ul class="gl-list-style-none gl-mb-0 gl-p-0">
      <diff-inline-findings-item
        v-for="finding in findings"
        :key="finding.description"
        :finding="finding"
      />
    </ul>
  </div>
</template>
