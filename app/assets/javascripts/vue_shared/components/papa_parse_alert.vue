<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlAlert,
  },
  i18n: {
    genericErrorMessage: s__('CsvParser|Failed to render the CSV file for the following reasons:'),
    MissingQuotes: s__('CsvParser|Quoted field unterminated'),
    InvalidQuotes: s__('CsvParser|Trailing quote on quoted field is malformed'),
    UndetectableDelimiter: s__('CsvParser|Unable to auto-detect delimiter; defaulted to ","'),
    TooManyFields: s__('CsvParser|Too many fields'),
    TooFewFields: s__('CsvParser|Too few fields'),
  },
  props: {
    papaParseErrors: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    errorMessages() {
      const errorMessages = this.papaParseErrors.map(
        (error) => this.$options.i18n[error.code] ?? error.message,
      );
      return new Set(errorMessages);
    },
  },
};
</script>

<template>
  <gl-alert variant="danger" :dismissible="false">
    {{ $options.i18n.genericErrorMessage }}
    <ul class="!gl-mb-0">
      <li v-for="error in errorMessages" :key="error">
        {{ error }}
      </li>
    </ul>
  </gl-alert>
</template>
