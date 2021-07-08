<script>
import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import Papa from 'papaparse';

export default {
  components: {
    GlTable,
    GlAlert,
    GlLoadingIcon,
  },
  props: {
    csv: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      items: [],
      errorMessage: null,
      loading: true,
    };
  },
  mounted() {
    const parsed = Papa.parse(this.csv, { skipEmptyLines: true });
    this.items = parsed.data;

    if (parsed.errors.length) {
      this.errorMessage = parsed.errors.map((e) => e.message).join('. ');
    }

    this.loading = false;
  },
};
</script>

<template>
  <div class="container-fluid md gl-mt-3 gl-mb-3">
    <div v-if="loading" class="gl-text-center loading">
      <gl-loading-icon class="gl-mt-5" size="lg" />
    </div>
    <div v-else>
      <gl-alert v-if="errorMessage" variant="danger" :dismissible="false">
        {{ errorMessage }}
      </gl-alert>
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
