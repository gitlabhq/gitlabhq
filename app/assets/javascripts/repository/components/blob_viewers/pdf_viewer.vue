<script>
import { GlButton } from '@gitlab/ui';
import PdfViewer from '~/blob/pdf/pdf_viewer.vue';
import { __ } from '~/locale';
import { PDF_MAX_FILE_SIZE, PDF_MAX_PAGE_LIMIT } from '../../constants';

export default {
  components: { GlButton, PdfViewer },
  i18n: {
    tooLargeDescription: __('This PDF is too large to display. Please download to view.'),
    tooLargeButtonText: __('Download PDF'),
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      url: this.blob.externalStorageUrl || this.blob.rawPath,
      fileSize: this.blob.rawSize,
      totalPages: 0,
    };
  },
  computed: {
    tooLargeToDisplay() {
      return this.fileSize > PDF_MAX_FILE_SIZE || this.totalPages > PDF_MAX_PAGE_LIMIT;
    },
  },
  methods: {
    handleOnLoad(totalPages) {
      this.totalPages = totalPages;
    },
  },
};
</script>
<template>
  <div>
    <pdf-viewer v-if="!tooLargeToDisplay" :pdf="url" @pdflabload="handleOnLoad" />

    <div v-else class="gl-flex gl-flex-col gl-items-center gl-p-5">
      <p>{{ $options.i18n.tooLargeDescription }}</p>

      <gl-button icon="download" category="secondary" variant="confirm" :href="url" download>{{
        $options.i18n.tooLargeButtonText
      }}</gl-button>
    </div>
  </div>
</template>
