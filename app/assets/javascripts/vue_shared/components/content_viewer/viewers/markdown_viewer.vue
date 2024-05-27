<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { forEach, escape } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

const { CancelToken } = axios;
let axiosSource;

export default {
  components: {
    GlSkeletonLoader,
  },
  directives: {
    SafeHtml,
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
            `${gon.relative_url_root}/${this.projectPath}/-/preview_markdown`,
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
              renderGFM(this.$refs.markdownPreview);
            });
          })
          .catch(() => {
            this.previewContent = __('An error occurred while fetching Markdown preview');
            this.isLoading = false;
          });
      }
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji', 'use'] },
};
</script>

<template>
  <div ref="markdownPreview" class="md-previewer" data-testid="md-previewer">
    <gl-skeleton-loader v-if="isLoading" />
    <div
      v-else
      v-safe-html:[$options.safeHtmlConfig]="previewContent"
      class="md gl-ml-auto gl-mr-auto"
    ></div>
  </div>
</template>
