<script>
import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';

import { GlSkeletonLoading } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { forEach, escape } from 'lodash';

const { CancelToken } = axios;
let axiosSource;

export default {
  components: {
    GlSkeletonLoading,
  },
  props: {
    content: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: '',
    },
    filePath: {
      type: String,
      required: false,
      default: '',
    },
    projectPath: {
      type: String,
      required: true,
    },
    images: {
      type: Object,
      required: false,
      default: () => ({}),
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
    if (this.isLoading) axiosSource.cancel(__('Cancelling Preview'));
  },
  methods: {
    fetchMarkdownPreview() {
      if (this.content && this.previewContent === null) {
        this.isLoading = true;
        const postBody = {
          text: this.content,
          path: this.filePath,
        };
        if (this.commitSha) {
          postBody.ref = this.commitSha;
        }
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
            let previewContent = data.body;
            forEach(this.images, ({ src, title = '', alt }, key) => {
              previewContent = previewContent.replace(
                key,
                `<img src="${escape(src)}" title="${escape(title)}" alt="${escape(alt)}">`,
              );
            });

            this.previewContent = previewContent;
            this.isLoading = false;

            this.$nextTick(() => {
              $(this.$refs.markdownPreview).renderGFM();
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
  <div ref="markdownPreview" class="md-previewer">
    <gl-skeleton-loading v-if="isLoading" />
    <div v-else class="md" v-html="previewContent"></div>
  </div>
</template>
