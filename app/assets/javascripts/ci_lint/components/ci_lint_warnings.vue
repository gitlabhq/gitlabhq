<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { __, n__ } from '~/locale';

export default {
  maxWarningsSummary: __('%{total} warnings found: showing first %{warningsDisplayed}'),
  components: {
    GlAlert,
    GlSprintf,
  },
  props: {
    warnings: {
      type: Array,
      required: true,
    },
    maxWarnings: {
      type: Number,
      required: false,
      default: 25,
    },
    title: {
      type: String,
      required: false,
      default: __('The form contains the following warning:'),
    },
  },
  computed: {
    totalWarnings() {
      return this.warnings.length;
    },
    overMaxWarningsLimit() {
      return this.totalWarnings > this.maxWarnings;
    },
    warningsSummary() {
      return n__('%d warning found:', '%d warnings found:', this.totalWarnings);
    },
    summaryMessage() {
      return this.overMaxWarningsLimit ? this.$options.maxWarningsSummary : this.warningsSummary;
    },
    limitWarnings() {
      return this.warnings.slice(0, this.maxWarnings);
    },
  },
};
</script>

<template>
  <gl-alert class="gl-mb-4" :title="title" variant="warning" @dismiss="$emit('dismiss')">
    <details>
      <summary>
        <gl-sprintf :message="summaryMessage">
          <template #total>
            {{ totalWarnings }}
          </template>
          <template #warningsDisplayed>
            {{ maxWarnings }}
          </template>
        </gl-sprintf>
      </summary>
      <p
        v-for="(warning, index) in limitWarnings"
        :key="`warning-${index}`"
        data-testid="ci-lint-warning"
      >
        {{ warning }}
      </p>
    </details>
  </gl-alert>
</template>
