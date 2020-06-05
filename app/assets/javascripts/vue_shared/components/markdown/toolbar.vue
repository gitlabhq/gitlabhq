<script>
import { GlButton, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
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
        <gl-link :href="markdownDocsPath" target="_blank">{{
          __('Markdown is supported')
        }}</gl-link>
      </template>
      <template v-if="hasQuickActionsDocsPath && markdownDocsPath">
        <gl-sprintf
          :message="
            __(
              '%{markdownDocsLinkStart}Markdown%{markdownDocsLinkEnd} and %{quickActionsDocsLinkStart}quick actions%{quickActionsDocsLinkEnd} are supported',
            )
          "
        >
          <template #markdownDocsLink="{content}">
            <gl-link :href="markdownDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
          <template #quickActionsDocsLink="{content}">
            <gl-link :href="quickActionsDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </div>
    <span v-if="canAttachFile" class="uploading-container">
      <span class="uploading-progress-container hide">
        <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i>
        <span class="attaching-file-message"></span>
        <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
        <span class="uploading-progress">0%</span>
        <gl-loading-icon inline class="align-text-bottom" />
      </span>
      <span class="uploading-error-container hide">
        <span class="uploading-error-icon">
          <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i>
        </span>
        <span class="uploading-error-message"></span>

        <gl-sprintf
          :message="
            __(
              '%{retryButtonStart}Try again%{retryButtonEnd} or %{newFileButtonStart}attach a new file%{newFileButtonEnd}',
            )
          "
        >
          <template #retryButton="{content}">
            <button class="retry-uploading-link" type="button">{{ content }}</button>
          </template>
          <template #newFileButton="{content}">
            <button class="attach-new-file markdown-selector" type="button">{{ content }}</button>
          </template>
        </gl-sprintf>
      </span>
      <gl-button class="markdown-selector button-attach-file" variant="link">
        <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i
        ><span class="text-attach-file">{{ __('Attach a file') }}</span>
      </gl-button>
      <gl-button class="btn btn-default btn-sm hide button-cancel-uploading-files" variant="link">
        {{ __('Cancel') }}
      </gl-button>
    </span>
  </div>
</template>
