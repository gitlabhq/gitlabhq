<script>
  export default {
    props: {
      markdownDocsPath: {
        type: String,
        required: true,
      },
      quickActionsDocsPath: {
        type: String,
        required: false,
        default: '',
      },
      canAttachFile: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    computed: {
      hasQuickActionsDocsPath() {
        return this.quickActionsDocsPath !== '';
      },
    },
  };
</script>

<template>
  <div class="comment-toolbar clearfix">
    <div class="toolbar-text">
      <template v-if="!hasQuickActionsDocsPath && markdownDocsPath">
        <a
          :href="markdownDocsPath"
          target="_blank"
          tabindex="-1"
        >
          Markdown is supported
        </a>
      </template>
      <template v-if="hasQuickActionsDocsPath && markdownDocsPath">
        <a
          :href="markdownDocsPath"
          target="_blank"
          tabindex="-1"
        >
          Markdown
        </a>
        and
        <a
          :href="quickActionsDocsPath"
          target="_blank"
          tabindex="-1"
        >
          quick actions
        </a>
        are supported
      </template>
    </div>
    <span
      v-if="canAttachFile"
      class="uploading-container"
    >
      <span class="uploading-progress-container d-none">
        <i
          class="fa fa-file-image-o toolbar-button-icon"
          aria-hidden="true"
        >
        </i>
        <span class="attaching-file-message"></span>
        <span class="uploading-progress">0%</span>
        <span class="uploading-spinner">
          <i
            class="fa fa-spinner fa-spin toolbar-button-icon"
            aria-hidden="true"
          >
          </i>
        </span>
      </span>
      <span class="uploading-error-container d-none">
        <span class="uploading-error-icon">
          <i
            class="fa fa-file-image-o toolbar-button-icon"
            aria-hidden="true"
          >
          </i>
        </span>
        <span class="uploading-error-message"></span>
        <button
          class="retry-uploading-link"
          type="button"
        >
          Try again
        </button>
        or
        <button
          class="attach-new-file markdown-selector"
          type="button"
        >
          attach a new file
        </button>
      </span>
      <button
        class="markdown-selector button-attach-file"
        tabindex="-1"
        type="button"
      >
        <i
          class="fa fa-file-image-o toolbar-button-icon"
          aria-hidden="true"
        >
        </i>
        Attach a file
      </button>
      <button
        class="btn btn-secondary btn-xs d-none button-cancel-uploading-files"
        type="button"
      >
        Cancel
      </button>
    </span>
  </div>
</template>
