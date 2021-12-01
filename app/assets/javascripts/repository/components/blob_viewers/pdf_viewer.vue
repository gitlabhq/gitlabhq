<script>
import PdfViewer from '~/blob/pdf/pdf_viewer.vue';

export default {
  components: { PdfViewer },
  props: {
    url: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <pdf-viewer :pdf="url" />
</template>
