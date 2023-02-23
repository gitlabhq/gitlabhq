<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';
import { NEW_CODE_QUALITY_FINDINGS } from '../i18n';

export default {
  i18n: {
    newFindings: NEW_CODE_QUALITY_FINDINGS,
  },
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
      <li
        v-for="finding in codeQuality"
        :key="finding.description"
        class="gl-pt-1 gl-pb-1 gl-font-regular gl-display-flex"
      >
        <span class="gl-mr-3">
          <gl-icon
            :size="12"
            :name="severityIcon(finding.severity)"
            :class="severityClass(finding.severity)"
            class="codequality-severity-icon"
          />
        </span>
        <span>
          <span class="severity-copy">{{ finding.severity }}</span> - {{ finding.description }}
        </span>
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
