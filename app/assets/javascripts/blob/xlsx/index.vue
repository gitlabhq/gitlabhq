<template>
  <div>
    <div
      class="text-center prepend-top-default append-bottom-default"
      aria-label="Loading Excel file"
      v-if="loading">
      <i
        class="fa fa-spinner fa-spin fa-2x"
        aria-hidden="true">
      </i>
    </div>
    <xlsx-tabs
      v-if="!loading && sheetNames"
      :current-sheet-name="currentSheetName"
      :sheet-names="sheetNames" />
    <xlsx-table
      v-if="!loading && sheet"
      :sheet="sheet" />
  </div>
</template>

<script>
import eventHub from './eventhub';
import Service from './service';
import xlsxTable from './components/table.vue';
import xlsxTabs from './components/tabs.vue';

export default {
  name: 'XLSXRenderer',
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentSheetName: '',
      data: {},
      loading: true,
    };
  },
  computed: {
    sheet() {
      return this.data[this.currentSheetName];
    },
    sheetNames() {
      return Object.keys(this.data);
    },
  },
  methods: {
    getInitialSheet() {
      let hash = location.hash.split('-');
      hash = decodeURIComponent(hash[0].replace('#', ''));

      return this.sheetNames.find(sheet => sheet === hash) || this.sheetNames[0];
    },
    updateSheetName(name) {
      this.currentSheetName = name;
    },
  },
  created() {
    this.service = new Service(this.endpoint);

    eventHub.$on('update-sheet', this.updateSheetName);
  },
  mounted() {
    this.service.getData()
      .then((data) => {
        this.data = data;
        this.currentSheetName = this.getInitialSheet();
        this.loading = false;
      });
  },
  beforeDestroy() {
    eventHub.$off('update-sheet', this.updateSheetName);
  },
  components: {
    xlsxTabs,
    xlsxTable,
  },
};
</script>
