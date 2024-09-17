<script>
import { GlLoadingIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import NotebookLab from '~/notebook/index.vue';

export default {
  components: {
    NotebookLab,
    GlLoadingIcon,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: false,
      loadError: false,
      loading: true,
      json: {},
    };
  },
  mounted() {
    if (gon.katex_css_url) {
      const katexStyles = document.createElement('link');
      katexStyles.setAttribute('rel', 'stylesheet');
      katexStyles.setAttribute('href', gon.katex_css_url);
      document.head.appendChild(katexStyles);
    }

    if (gon.katex_js_url) {
      const katexScript = document.createElement('script');
      katexScript.addEventListener('load', () => {
        this.loadFile();
      });
      katexScript.setAttribute('src', gon.katex_js_url);
      document.head.appendChild(katexScript);
    } else {
      this.loadFile();
    }
  },
  methods: {
    loadFile() {
      axios
        .get(this.endpoint)
        .then((res) => res.data)
        .then((data) => {
          this.json = data;
          this.loading = false;
        })
        .catch((e) => {
          if (e.status !== HTTP_STATUS_OK) {
            this.loadError = true;
          }
          this.error = true;
        });
    },
  },
};
</script>

<template>
  <div class="js-notebook-viewer-mounted container-fluid md gl-mb-3 gl-mt-3">
    <div v-if="loading && !error" class="text-center loading">
      <gl-loading-icon class="mt-5" size="lg" />
    </div>
    <notebook-lab v-if="!loading && !error" :notebook="json" />
    <p v-if="error" class="text-center">
      <span v-if="loadError" ref="loadErrorMessage">{{
        __('An error occurred while loading the file. Please try again later.')
      }}</span>
      <span v-else ref="parsingErrorMessage">{{
        __('An error occurred while parsing the file.')
      }}</span>
    </p>
  </div>
</template>

<style>
.output img {
  min-width: 0; /* https://www.w3.org/TR/css-flexbox-1/#min-size-auto */
}

.output .markdown {
  display: block;
  width: 100%;
}
</style>
