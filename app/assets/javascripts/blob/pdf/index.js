import Vue from 'vue';
import pdfLab from '../../pdf/index.vue';
import { GlLoadingIcon } from '@gitlab/ui';

export default () => {
  const el = document.getElementById('js-pdf-viewer');

  return new Vue({
    el,
    components: {
      pdfLab,
      GlLoadingIcon,
    },
    data() {
      return {
        error: false,
        loadError: false,
        loading: true,
        pdf: el.dataset.endpoint,
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
    template: `
      <div class="js-pdf-viewer container-fluid md prepend-top-default append-bottom-default">
        <div
          class="text-center loading"
          v-if="loading && !error">
          <gl-loading-icon class="mt-5" size="lg"/>
        </div>
        <pdf-lab
          v-if="!loadError"
          :pdf="pdf"
          @pdflabload="onLoad"
          @pdflaberror="onError" />
        <p
          class="text-center"
          v-if="error">
          <span v-if="loadError">
            An error occurred while loading the file. Please try again later.
          </span>
          <span v-else>
            An error occurred while decoding the file.
          </span>
        </p>
      </div>
    `,
  });
};
