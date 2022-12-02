<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';

export default {
  components: { GlButton, GlIcon },
  props: {
    codeQuality: {
      type: Array,
      required: true,
    },
  },
  methods: {
    severityClass(severity) {
      return SEVERITY_CLASSES[severity] || SEVERITY_CLASSES.unknown;
    },
    severityIcon(severity) {
      return SEVERITY_ICONS[severity] || SEVERITY_ICONS.unknown;
    },
  },
};
</script>

<template>
  <div data-testid="diff-codequality" class="gl-relative">
    <ul
      class="gl-list-style-none gl-mb-0 gl-p-0 codequality-findings-list gl-border-top-1 gl-border-bottom-1 gl-bg-gray-10"
    >
      <li
        v-for="finding in codeQuality"
        :key="finding.description"
        class="gl-pt-1 gl-pb-1 gl-pl-3 gl-border-solid gl-border-bottom-0 gl-border-right-0 gl-border-1 gl-border-gray-100 gl-font-regular"
      >
        <gl-icon
          :size="12"
          :name="severityIcon(finding.severity)"
          :class="severityClass(finding.severity)"
          class="codequality-severity-icon"
        />
        {{ finding.description }}
      </li>
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
