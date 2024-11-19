<script>
import { GlLoadingIcon, GlTable, GlButton } from '@gitlab/ui';
import Papa from 'papaparse';
import { setUrlParams } from '~/lib/utils/url_utility';
import PapaParseAlert from '../components/papa_parse_alert.vue';
import { MAX_ROWS_TO_RENDER } from './constants';

export default {
  components: {
    PapaParseAlert,
    GlTable,
    GlButton,
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
      isTooLarge: false,
    };
  },
  computed: {
    pathToRawFile() {
      return setUrlParams({ plain: 1 });
    },
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
      if (parsed.data.length > MAX_ROWS_TO_RENDER) {
        this.isTooLarge = true;
      }

      this.items = parsed.data.slice(0, MAX_ROWS_TO_RENDER);

      if (parsed.errors.length) {
        this.papaParseErrors = parsed.errors;
      }

      this.loading = false;
    },
  },
};
</script>

<template>
  <div class="container-fluid md gl-mb-3 gl-mt-3">
    <div v-if="loading" class="loading gl-text-center">
      <gl-loading-icon class="gl-mt-5" size="lg" />
    </div>
    <div v-else>
      <papa-parse-alert v-if="papaParseErrors.length" :papa-parse-errors="papaParseErrors" />
      <gl-table
        :empty-text="s__('CsvViewer|No CSV data to display.')"
        :items="items"
        :fields="$options.fields"
        show-empty
        thead-class="gl-hidden"
      />
      <div v-if="isTooLarge" class="gl-flex gl-flex-col gl-items-center gl-p-5">
        <p data-testid="large-csv-text">
          {{
            s__(
              'CsvViewer|The file is too large to render all the rows. To see the entire file, switch to the raw view.',
            )
          }}
        </p>

        <gl-button category="secondary" variant="confirm" :href="pathToRawFile">{{
          s__('CsvViewer|View raw data')
        }}</gl-button>
      </div>
    </div>
  </div>
</template>
