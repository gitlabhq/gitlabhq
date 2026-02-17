<script>
import { GlIcon, GlTableLite } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'DbCollationMismatches',
  components: { GlIcon, GlTableLite },
  props: {
    collationMismatches: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasMismatches() {
      return Boolean(this.collationMismatches.length);
    },
    iconAttrs() {
      return {
        name: this.hasMismatches ? 'information-o' : 'check-circle-filled',
        variant: this.hasMismatches ? 'info' : 'success',
        'data-testid': 'collation-mismatches-icon',
      };
    },
  },
  collationMismatchFields: [
    { key: 'collation_name', label: __('Collation name') },
    { key: 'provider', label: __('Provider') },
    { key: 'stored_version', label: __('Stored version') },
    { key: 'actual_version', label: __('Actual version') },
  ],
};
</script>

<template>
  <section>
    <h4 class="gl-heading-5 gl-flex gl-items-center gl-gap-3">
      <gl-icon v-bind="iconAttrs" />
      {{ __('Collation mismatches') }}
    </h4>

    <template v-if="hasMismatches">
      <p class="gl-text-sm gl-text-subtle" data-testid="collation-info-alert">
        {{
          s__(
            'DatabaseDiagnostics|Collation mismatches are informational and might not indicate a problem.',
          )
        }}
      </p>
      <gl-table-lite
        :items="collationMismatches"
        :fields="$options.collationMismatchFields"
        stacked="md"
        data-testid="collation-mismatches-table"
      />
    </template>
    <template v-else>
      <p class="gl-text-sm gl-text-subtle" data-testid="no-collation-mismatches-alert">
        {{ __('No collation mismatches detected.') }}
      </p>
    </template>
  </section>
</template>
