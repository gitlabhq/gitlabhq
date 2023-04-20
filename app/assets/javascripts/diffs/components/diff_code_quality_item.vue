<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: { GlLink, GlIcon },
  mixins: [glFeatureFlagsMixin()],
  props: {
    finding: {
      type: Object,
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
    toggleDrawer() {
      this.setDrawer(this.finding);
    },
    ...mapActions('findingsDrawer', ['setDrawer']),
  },
};
</script>

<template>
  <li class="gl-py-1 gl-font-regular gl-display-flex">
    <span class="gl-mr-3">
      <gl-icon
        :size="12"
        :name="severityIcon(finding.severity)"
        :class="severityClass(finding.severity)"
        class="codequality-severity-icon"
      />
    </span>
    <span
      v-if="glFeatures.codeQualityInlineDrawer"
      data-testid="description-button-section"
      class="gl-display-flex"
    >
      <gl-link category="primary" variant="link" @click="toggleDrawer">
        {{ finding.severity }} - {{ finding.description }}</gl-link
      >
    </span>
    <span v-else data-testid="description-plain-text" class="gl-display-flex">
      {{ finding.severity }} - {{ finding.description }}
    </span>
  </li>
</template>
