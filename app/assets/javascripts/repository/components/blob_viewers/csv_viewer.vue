<script>
import CsvViewer from '~/blob/csv/csv_viewer.vue';

export default {
  components: {
    CsvViewer,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      url: this.blob.rawPath,
    };
  },
};
</script>

<template>
  <div>
    <csv-viewer :csv="url" remote-file data-testid="csv" />
  </div>
</template>
