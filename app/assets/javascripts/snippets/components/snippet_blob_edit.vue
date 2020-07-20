<script>
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import BlobContentEdit from '~/blob/components/blob_edit_content.vue';
import { GlLoadingIcon } from '@gitlab/ui';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { SNIPPET_BLOB_CONTENT_FETCH_ERROR } from '~/snippets/constants';
import Flash from '~/flash';
import { sprintf } from '~/locale';

function localId() {
  return Math.floor((1 + Math.random()) * 0x10000)
    .toString(16)
    .substring(1);
}

export default {
  components: {
    BlobHeaderEdit,
    BlobContentEdit,
    GlLoadingIcon,
  },
  inheritAttrs: false,
  props: {
    blob: {
      type: Object,
      required: false,
      default: null,
      validator: ({ rawPath }) => Boolean(rawPath),
    },
  },
  data() {
    return {
      id: localId(),
      filePath: this.blob?.path || '',
      previousPath: '',
      originalPath: this.blob?.path || '',
      content: this.blob?.content || '',
      originalContent: '',
      isContentLoading: this.blob,
    };
  },
  watch: {
    filePath(filePath, previousPath) {
      this.previousPath = previousPath;
      this.notifyAboutUpdates({ previousPath });
    },
    content() {
      this.notifyAboutUpdates();
    },
  },
  mounted() {
    if (this.blob) {
      this.fetchBlobContent();
    }
  },
  methods: {
    notifyAboutUpdates(args = {}) {
      const { filePath, previousPath } = args;
      this.$emit('blob-updated', {
        filePath: filePath || this.filePath,
        previousPath: previousPath || this.previousPath,
        content: this.content,
        _constants: {
          originalPath: this.originalPath,
          originalContent: this.originalContent,
          id: this.id,
        },
      });
    },
    fetchBlobContent() {
      const baseUrl = getBaseURL();
      const url = joinPaths(baseUrl, this.blob.rawPath);

      axios
        .get(url)
        .then(res => {
          this.originalContent = res.data;
          this.content = res.data;
        })
        .catch(e => this.flashAPIFailure(e))
        .finally(() => {
          this.isContentLoading = false;
        });
    },
    flashAPIFailure(err) {
      Flash(sprintf(SNIPPET_BLOB_CONTENT_FETCH_ERROR, { err }));
      this.isContentLoading = false;
    },
  },
};
</script>
<template>
  <div class="form-group file-editor">
    <label>{{ s__('Snippets|File') }}</label>
    <div class="file-holder snippet">
      <blob-header-edit v-model="filePath" data-qa-selector="file_name_field" />
      <gl-loading-icon
        v-if="isContentLoading"
        :label="__('Loading snippet')"
        size="lg"
        class="loading-animation prepend-top-20 append-bottom-20"
      />
      <blob-content-edit v-else v-model="content" :file-name="filePath" />
    </div>
  </div>
</template>
