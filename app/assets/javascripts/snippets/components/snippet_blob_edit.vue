<script>
import { GlLoadingIcon } from '@gitlab/ui';
import SnippetBlobEditHeader from '~/snippets/components/snippet_blob_edit_header.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import { SNIPPET_BLOB_CONTENT_FETCH_ERROR } from '~/snippets/constants';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import { EDITOR_READY_EVENT } from '~/editor/constants';
import { BLOB_EDITOR_ERROR } from '~/blob_edit/constants';
import { hasMarkdownExtension } from '~/blob/utils';

export default {
  name: 'SnippetBlobEdit',
  components: {
    SnippetBlobEditHeader,
    GlLoadingIcon,
    SourceEditor,
  },
  inheritAttrs: false,
  props: {
    blob: {
      type: Object,
      required: true,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: true,
    },
    showDelete: {
      type: Boolean,
      required: false,
      default: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
  },
  emits: ['blob-updated', 'delete'],
  computed: {
    inputId() {
      return `${this.blob.id}_file_path`;
    },
    isMarkdown() {
      return hasMarkdownExtension(this.blob.path);
    },
  },
  mounted() {
    if (!this.blob.isLoaded) {
      this.fetchBlobContent();
    }
  },
  methods: {
    async onEditorReady({ detail: { instance } }) {
      if (!this.isMarkdown) {
        return;
      }

      try {
        const { EditorMarkdownPreviewExtension } =
          await import('~/editor/extensions/source_editor_markdown_livepreview_ext');

        instance.use({
          definition: EditorMarkdownPreviewExtension,
          setupOptions: { previewMarkdownPath: this.markdownPreviewPath },
        });
      } catch (e) {
        createAlert({ message: `${BLOB_EDITOR_ERROR}: ${e}` });
      }
    },
    onDelete() {
      this.$emit('delete');
    },
    notifyAboutUpdates(args = {}) {
      this.$emit('blob-updated', args);
    },
    fetchBlobContent() {
      const baseUrl = getBaseURL();
      const url = joinPaths(baseUrl, this.blob.rawPath);

      axios
        .get(url, {
          // This prevents axios from automatically JSON.parse response
          transformResponse: [(f) => f],
          headers: { 'Cache-Control': 'no-cache' },
        })
        .then((res) => {
          this.notifyAboutUpdates({ content: res.data });
        })
        .catch((e) => this.alertAPIFailure(e));
    },
    alertAPIFailure(err) {
      createAlert({ message: sprintf(SNIPPET_BLOB_CONTENT_FETCH_ERROR, { err }) });
    },
  },
  readyEvent: EDITOR_READY_EVENT,
};
</script>
<template>
  <div class="file-holder snippet" data-testid="file-holder-container">
    <snippet-blob-edit-header
      :id="inputId"
      :value="blob.path"
      data-testid="file-name-field"
      :can-delete="canDelete"
      :show-delete="showDelete"
      @input="notifyAboutUpdates({ path: $event })"
      @delete="onDelete"
    />
    <gl-loading-icon
      v-if="!blob.isLoaded"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation gl-mb-6 gl-mt-5"
    />
    <source-editor
      v-else
      :value="blob.content"
      :file-global-id="blob.id"
      :file-name="blob.path"
      @[$options.readyEvent]="onEditorReady"
      @input="notifyAboutUpdates({ content: $event })"
    />
  </div>
</template>
