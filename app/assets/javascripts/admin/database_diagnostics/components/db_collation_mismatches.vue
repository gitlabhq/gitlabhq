<script>
import { GlIcon, GlAlert, GlTableLite } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'DbCollationMismatches',
  components: { GlIcon, GlAlert, GlTableLite },
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
    <p>
      <gl-icon v-bind="iconAttrs" />
      <strong>{{ __('Collation mismatches') }}</strong>
    </p>

    <template v-if="hasMismatches">
      <gl-alert
        variant="info"
        data-testid="collation-info-alert"
        :dismissible="false"
        class="gl-mb-3"
      >
        {{
          s__(
            'DatabaseDiagnostics|Collation mismatches are informational and might not indicate a problem.',
          )
        }}
      </gl-alert>
      <gl-table-lite
        :items="collationMismatches"
        :fields="$options.collationMismatchFields"
        bordered
        stacked="md"
        data-testid="collation-mismatches-table"
      />
    </template>
    <template v-else>
      <gl-alert variant="success" data-testid="no-collation-mismatches-alert" :dismissible="false">
        {{ __('No collation mismatches detected.') }}
      </gl-alert>
    </template>
  </section>
</template>
