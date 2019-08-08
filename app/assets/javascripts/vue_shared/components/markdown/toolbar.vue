<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
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
        <gl-link :href="markdownDocsPath" target="_blank" tabindex="-1">{{
          __('Markdown is supported')
        }}</gl-link>
      </template>
      <template v-if="hasQuickActionsDocsPath && markdownDocsPath">
        <gl-link :href="markdownDocsPath" target="_blank" tabindex="-1">{{
          __('Markdown')
        }}</gl-link>
        and
        <gl-link :href="quickActionsDocsPath" target="_blank" tabindex="-1">{{
          __('quick actions')
        }}</gl-link>
        are supported
      </template>
    </div>
    <span v-if="canAttachFile" class="uploading-container">
      <span class="uploading-progress-container hide">
        <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i>
        <span class="attaching-file-message"></span>
        <span class="uploading-progress">0%</span>
        <span class="uploading-spinner">
          <i class="fa fa-spinner fa-spin toolbar-button-icon" aria-hidden="true"></i>
        </span>
      </span>
      <span class="uploading-error-container hide">
        <span class="uploading-error-icon">
          <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i>
        </span>
        <span class="uploading-error-message"></span>
        <button class="retry-uploading-link" type="button">{{ __('Try again') }}</button> or
        <button class="attach-new-file markdown-selector" type="button">
          {{ __('attach a new file') }}
        </button>
      </span>
      <button class="markdown-selector button-attach-file btn-link" tabindex="-1" type="button">
        <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i
        ><span class="text-attach-file">{{ __('Attach a file') }}</span>
      </button>
      <button class="btn btn-default btn-sm hide button-cancel-uploading-files" type="button">
        {{ __('Cancel') }}
      </button>
    </span>
  </div>
</template>
