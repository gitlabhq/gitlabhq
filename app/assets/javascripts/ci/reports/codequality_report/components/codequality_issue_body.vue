<script>
/**
 * Renders Code quality body text
 * Fixed: [name] in [link]:[line]
 */
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import ReportLink from '~/ci/reports/components/report_link.vue';
import { STATUS_SUCCESS, STATUS_NEUTRAL } from '~/ci/reports/constants';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '../constants';

export default {
  name: 'CodequalityIssueBody',
  components: {
    GlIcon,
    ReportLink,
  },
  directives: {
    tooltip: GlTooltipDirective,
  },
  props: {
    status: {
      type: String,
      required: false,
      default: STATUS_NEUTRAL,
    },
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    issueName() {
      return `${this.severityLabel} - ${this.issue.name}`;
    },
    issueSeverity() {
      return this.issue.severity?.toLowerCase();
    },
    isStatusSuccess() {
      return this.status === STATUS_SUCCESS;
    },
    severityClass() {
      return SEVERITY_CLASSES[this.issueSeverity] || SEVERITY_CLASSES.unknown;
    },
    severityIcon() {
      return SEVERITY_ICONS[this.issueSeverity] || SEVERITY_ICONS.unknown;
    },
    severityLabel() {
      return this.$options.severityText[this.issueSeverity] || this.$options.severityText.unknown;
    },
  },
  severityText: {
    info: s__('severity|Info'),
    minor: s__('severity|Minor'),
    major: s__('severity|Major'),
    critical: s__('severity|Critical'),
    blocker: s__('severity|Blocker'),
    unknown: s__('severity|Unknown'),
  },
};
</script>
<template>
  <div class="gl-mb-2 gl-mt-2 gl-flex gl-w-full">
    <span :class="severityClass" class="gl-mr-5" data-testid="codequality-severity-icon">
      <gl-icon v-tooltip="severityLabel" :name="severityIcon" :size="12" />
    </span>
    <div class="gl-grow">
      <div>
        <strong v-if="isStatusSuccess">{{ s__('ciReport|Fixed:') }}</strong>
        {{ issueName }}
      </div>

      <report-link v-if="issue.path" :issue="issue" />
    </div>
  </div>
</template>
