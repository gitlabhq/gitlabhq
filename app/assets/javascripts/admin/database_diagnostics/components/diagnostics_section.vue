<script>
import { GlAlert, GlBadge, GlButton, GlCollapse, GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { s__ } from '~/locale';
import { severityIcon, severityVariant } from '../utils';

export default {
  name: 'DiagnosticsSection',
  components: { GlAlert, GlBadge, GlButton, GlCollapse, GlIcon },
  props: {
    title: {
      type: String,
      required: true,
    },
    // Prefixes the data-testids, so each caller stays addressable in its own specs.
    testidPrefix: {
      type: String,
      required: true,
    },
    // The verdict the check reached. Null means it found nothing.
    severity: {
      type: String,
      required: false,
      default: null,
    },
    // Ordered and scored by the check, so no ordering is applied here.
    findings: {
      type: Array,
      required: false,
      default: () => [],
    },
    // False when the check read nothing, which leaves no details to fold out and
    // no verdict to report.
    foldable: {
      type: Boolean,
      required: false,
      default: true,
    },
    // False for a check that presents its findings itself, for example as a badge
    // per row. The count badge in the header is shown either way.
    showFindingAlerts: {
      type: Boolean,
      required: false,
      default: true,
    },
    // Replaces the number of findings in the header badge, for a section that
    // counts something else, for example tables.
    count: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      expanded: false,
      detailsId: uniqueId(`${this.testidPrefix}-details-`),
    };
  },
  computed: {
    alerts() {
      return this.showFindingAlerts ? this.findings : [];
    },
    badgeCount() {
      return this.count ?? this.findings.length;
    },
    // No severity means nothing is wrong, so the count is only informational.
    badgeVariant() {
      return this.severity ? severityVariant(this.severity) : 'neutral';
    },
  },
  methods: {
    severityIcon,
    severityVariant,
    toggle() {
      this.expanded = !this.expanded;
    },
  },
  i18n: {
    details: s__('DatabaseDiagnostics|Details'),
  },
};
</script>

<template>
  <div>
    <!-- Status icon summarises the check while the details are collapsed. -->
    <div class="gl-flex gl-items-center gl-justify-between gl-rounded-base gl-bg-subtle gl-p-3">
      <div class="gl-flex gl-items-center gl-gap-2">
        <gl-icon
          v-if="foldable"
          v-bind="severityIcon(severity)"
          :data-testid="`${testidPrefix}-status-icon`"
        />
        <h4 class="gl-heading-5 !gl-mb-0">{{ title }}</h4>
        <gl-badge v-if="badgeCount" :variant="badgeVariant" :data-testid="`${testidPrefix}-count`">
          {{ badgeCount }}
        </gl-badge>
      </div>

      <gl-button
        v-if="foldable"
        category="tertiary"
        size="small"
        :data-testid="`${testidPrefix}-toggle`"
        :icon="expanded ? 'chevron-up' : 'chevron-down'"
        :aria-expanded="expanded.toString()"
        :aria-controls="detailsId"
        @click="toggle"
      >
        {{ $options.i18n.details }}
      </gl-button>
    </div>

    <gl-collapse
      v-if="foldable"
      :id="detailsId"
      :visible="expanded"
      class="gl-mt-3"
      :data-testid="`${testidPrefix}-details`"
    >
      <gl-alert
        v-for="(finding, index) in alerts"
        :key="`${finding.code}-${index}`"
        :variant="severityVariant(finding.severity)"
        :dismissible="false"
        class="gl-mb-3"
        :data-testid="`${testidPrefix}-finding-${finding.code}`"
      >
        {{ finding.message }}
      </gl-alert>

      <slot></slot>
    </gl-collapse>
  </div>
</template>
