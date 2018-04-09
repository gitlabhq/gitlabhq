<script>
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import $ from 'jquery';
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';

const CancelToken = axios.CancelToken;
let axiosSource;

export default {
  components: {
    SkeletonLoadingContainer,
  },
  props: {
    content: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      previewContent: null,
      isLoading: false,
    };
  },
  watch: {
    content() {
      this.previewContent = null;
    },
  },
  created() {
    axiosSource = CancelToken.source();
    this.fetchMarkdownPreview();
  },
  updated() {
    this.fetchMarkdownPreview();
  },
  destroyed() {
    if (this.isLoading) axiosSource.cancel('Cancelling Preview');
  },
  methods: {
    fetchMarkdownPreview() {
      if (this.content && this.previewContent === null) {
        this.isLoading = true;
        const postBody = {
          text: this.content,
        };
        const postOptions = {
          cancelToken: axiosSource.token,
        };

        axios
          .post(
            `${gon.relative_url_root}/${this.projectPath}/preview_markdown`,
            postBody,
            postOptions,
          )
          .then(({ data }) => {
            this.previewContent = data.body;
            this.isLoading = false;

            this.$nextTick(() => {
              $(this.$refs['markdown-preview']).renderGFM();
            });
          })
          .catch(() => {
            this.previewContent = __('An error occurred while fetching markdown preview');
            this.isLoading = false;
          });
      }
    },
  },
};
</script>

<template>
  <div
    ref="markdown-preview"
    class="md md-previewer">
    <skeleton-loading-container v-if="isLoading" />
    <div
      v-else
      v-html="previewContent">
    </div>
  </div>
</template>
