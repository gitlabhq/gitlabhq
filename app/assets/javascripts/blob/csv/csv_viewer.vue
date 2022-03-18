<script>
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import Papa from 'papaparse';
import PapaParseAlert from '~/vue_shared/components/papa_parse_alert.vue';

export default {
  components: {
    PapaParseAlert,
    GlTable,
    GlLoadingIcon,
  },
  props: {
    csv: {
      type: String,
      required: true,
    },
    remoteFile: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      items: [],
      papaParseErrors: [],
      loading: true,
    };
  },
  mounted() {
    if (!this.remoteFile) {
      const parsed = Papa.parse(this.csv, { skipEmptyLines: true });
      this.handleParsedData(parsed);
    } else {
      Papa.parse(this.csv, {
        download: true,
        skipEmptyLines: true,
        complete: (parsed) => {
          this.handleParsedData(parsed);
        },
      });
    }
  },
  methods: {
    handleParsedData(parsed) {
      this.items = parsed.data;

      if (parsed.errors.length) {
        this.papaParseErrors = parsed.errors;
      }

      this.loading = false;
    },
  },
};
</script>

<template>
  <div class="container-fluid md gl-mt-3 gl-mb-3">
    <div v-if="loading" class="gl-text-center loading">
      <gl-loading-icon class="gl-mt-5" size="lg" />
    </div>
    <div v-else>
      <papa-parse-alert v-if="papaParseErrors.length" :papa-parse-errors="papaParseErrors" />
      <gl-table
        :empty-text="__('No CSV data to display.')"
        :items="items"
        :fields="$options.fields"
        show-empty
        thead-class="gl-display-none"
      />
    </div>
  </div>
</template>
