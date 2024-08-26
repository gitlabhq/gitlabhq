<script>
import { GlLoadingIcon } from '@gitlab/ui';
import PdfLab from '~/pdf/index.vue';

export default {
  components: {
    PdfLab,
    GlLoadingIcon,
  },
  props: {
    pdf: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: false,
      loadError: false,
      loading: true,
    };
  },
  methods: {
    onLoad() {
      this.loading = false;
    },
    onError(error) {
      this.loading = false;
      this.loadError = true;
      this.error = error;
    },
  },
};
</script>

<template>
  <div class="js-pdf-viewer container-fluid md gl-mb-3 gl-mt-3">
    <div v-if="loading && !error" class="text-center loading">
      <gl-loading-icon class="mt-5" size="lg" />
    </div>
    <pdf-lab
      v-if="!loadError"
      :pdf="pdf"
      @pdflabload="onLoad"
      @pdflaberror="onError"
      v-on="$listeners"
    />
    <p v-if="error" class="text-center">
      <span v-if="loadError" ref="loadError">
        {{ __('An error occurred while loading the file. Please try again later.') }}
      </span>
      <span v-else>{{ __('An error occurred while decoding the file.') }}</span>
    </p>
  </div>
</template>
