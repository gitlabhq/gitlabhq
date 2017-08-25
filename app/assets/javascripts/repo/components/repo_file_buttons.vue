<script>
import Store from '../stores/repo_store';
import Helper from '../helpers/repo_helper';
import RepoMixin from '../mixins/repo_mixin';
import BlobViewerMixin from '../mixins/blob_viewer_mixin';

export default {
  data: () => Store,
  props: {
    activeBlobViewers: { type: Object, required: false },
    selectedBlobViewerType: { type: String, required: false },
  },
  mixins: [RepoMixin, BlobViewerMixin],

  computed: {
    rawDownloadButtonLabel() {
      return this.binary ? 'Download' : 'Raw';
    },

    canPreview() {
      return Helper.isRenderable();
    },

    copySourceStatus() {
      if (!this.viewerIsSimple) {
        return `Switch to the source to copy it to the clipboard`;
      }

      return `Copy source to clipboard`;
    }
  },

  methods: {
    rawPreviewToggle: Store.toggleRawPreview,
  },
};
</script>

<template>
  <div id="repo-file-buttons">
    <a
      :href="activeFile.raw_path"
      target="_blank"
      class="btn btn-default raw"
      rel="noopener noreferrer">
      {{rawDownloadButtonLabel}}
    </a>

    <div class="viewer-switcher btn-group">
      <button
        v-if="canDisplayRichViewer"
        aria-label="Display source"
        class="btn btn-default btn-sm js-blob-viewer-switch-btn has-tooltip"
        :class='{ active: viewerIsSimple }'
        :disabled="viewerIsSimple"
        data-container="body"
        title=""
        data-original-title="Display source">
        <i
          aria-hidden="true"
          data-hidden="true"
          class="fa fa-code">
        </i>
      </button>

      <button
        v-if="canDisplayRichViewer"
        aria-label="Display rendered file"
        class="btn btn-default btn-sm js-blob-viewer-switch-btn has-tooltip active"
        :class='{ active: viewerIsRich }'
        :disabled="viewerIsRich"
        data-container="body"
        title=""
        data-original-title="Display rendered file">
        <i
          aria-hidden="true"
          data-hidden="true"
          class="fa fa-file-text-o">
        </i>
      </button>

      <button
        class="btn btn-sm js-copy-blob-source-btn"
        data-toggle="tooltip"
        data-placement="bottom"
        data-container="body"
        data-class="btn btn-sm js-copy-blob-source-btn"
        data-title="Copy source to clipboard"
        data-clipboard-target=".blob-content[data-blob-id='cc85e5de40f49d03b59fdaffaafa23a18a07acb2']"
        :disabled="viewerIsRich"
        type="button"
        title="copySourceStatus"
        aria-label="Copy source to clipboard"
        data-original-title="Copy source to clipboard">
        <i
          aria-hidden="true"
          data-hidden="true"
          class="fa fa-clipboard">
        </i>
      </button>

      <a
        class="btn btn-sm has-tooltip"
        target="_blank"
        rel="noopener noreferrer"
        title=""
        data-container="body"
        href="/gitlab-org/gitlab-ce/raw/master/app/views/projects/blob/_viewer.html.haml"
        data-original-title="Open raw">
        <i
          aria-hidden="true"
          data-hidden="true"
          class="fa fa-file-code-o">
        </i>
      </a>
    </div>
    <div
      class="btn-group"
      role="group"
      aria-label="File actions">
      <a
        :href="activeFile.blame_path"
        class="btn btn-default blame">
        Blame
      </a>
      <a
        :href="activeFile.commits_path"
        class="btn btn-default history">
        History
      </a>
      <a
        :href="activeFile.permalink"
        class="btn btn-default permalink">
        Permalink
      </a>
    </div>

    <a
      v-if="canPreview"
      href="#"
      @click.prevent="rawPreviewToggle"
      class="btn btn-default preview">
      {{activeFileLabel}}
    </a>
  </div>
</template>
