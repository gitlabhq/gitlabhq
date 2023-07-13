<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { getSeverity } from '~/ci/reports/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: { GlLink, GlIcon },
  mixins: [glFeatureFlagsMixin()],
  props: {
    finding: {
      type: Object,
      required: true,
    },
    link: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    enhancedFinding() {
      return getSeverity(this.finding);
    },
    listText() {
      return `${this.finding.severity} - ${this.finding.description}`;
    },
  },
  methods: {
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
        :name="enhancedFinding.name"
        :class="enhancedFinding.class"
        class="codequality-severity-icon"
      />
    </span>
    <span
      v-if="glFeatures.codeQualityInlineDrawer"
      data-testid="description-button-section"
      class="gl-display-flex"
    >
      <gl-link v-if="link" category="primary" variant="link" @click="toggleDrawer">
        {{ listText }}</gl-link
      >
      <span v-else>{{ listText }}</span>
    </span>
    <span v-else data-testid="description-plain-text" class="gl-display-flex">
      {{ listText }}
    </span>
  </li>
</template>
