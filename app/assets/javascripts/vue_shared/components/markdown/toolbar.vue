<script>
import { GlButton, GlLink, GlLoadingIcon, GlSprintf, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlIcon,
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
    showCommentToolBar: {
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
  <div
    v-if="showCommentToolBar"
    class="comment-toolbar gl-mx-2 gl-mb-2 gl-px-4 gl-bg-gray-10 gl-rounded-bottom-left-base gl-rounded-bottom-right-base clearfix"
  >
    <div class="toolbar-text gl-font-sm">
      <template v-if="!hasQuickActionsDocsPath && markdownDocsPath">
        <gl-sprintf
          :message="
            s__('MarkdownToolbar|Supports %{markdownDocsLinkStart}Markdown%{markdownDocsLinkEnd}')
          "
        >
          <template #markdownDocsLink="{ content }">
            <gl-link :href="markdownDocsPath" target="_blank" class="gl-font-sm">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
      <template v-if="hasQuickActionsDocsPath && markdownDocsPath">
        <gl-sprintf
          :message="
            s__(
              'NoteToolbar|Supports %{markdownDocsLinkStart}Markdown%{markdownDocsLinkEnd}. For %{quickActionsDocsLinkStart}quick actions%{quickActionsDocsLinkEnd}, type %{keyboardStart}/%{keyboardEnd}.',
            )
          "
        >
          <template #markdownDocsLink="{ content }">
            <gl-link :href="markdownDocsPath" target="_blank" class="gl-font-sm">{{
              content
            }}</gl-link>
          </template>
          <template #keyboard="{ content }">
            <kbd>{{ content }}</kbd>
          </template>
          <template #quickActionsDocsLink="{ content }">
            <gl-link :href="quickActionsDocsPath" target="_blank" class="gl-font-sm">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </div>
    <span v-if="canAttachFile" class="uploading-container gl-font-sm gl-line-height-32">
      <span class="uploading-progress-container hide">
        <gl-icon name="paperclip" />
        <span class="attaching-file-message"></span>
        <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
        <span class="uploading-progress">0%</span>
        <gl-loading-icon size="sm" inline />
      </span>
      <span class="uploading-error-container hide">
        <span class="uploading-error-icon">
          <gl-icon name="paperclip" />
        </span>
        <span class="uploading-error-message"></span>

        <gl-sprintf
          :message="
            __(
              '%{retryButtonStart}Try again%{retryButtonEnd} or %{newFileButtonStart}attach a new file%{newFileButtonEnd}.',
            )
          "
        >
          <template #retryButton="{ content }">
            <gl-button
              variant="link"
              category="primary"
              class="retry-uploading-link gl-vertical-align-baseline gl-font-sm!"
            >
              {{ content }}
            </gl-button>
          </template>
          <template #newFileButton="{ content }">
            <gl-button
              variant="link"
              category="primary"
              class="markdown-selector attach-new-file gl-vertical-align-baseline gl-font-sm!"
            >
              {{ content }}
            </gl-button>
          </template>
        </gl-sprintf>
      </span>
      <gl-button
        variant="link"
        category="primary"
        class="button-cancel-uploading-files gl-vertical-align-baseline hide gl-font-sm!"
      >
        {{ __('Cancel') }}
      </gl-button>
    </span>
  </div>
</template>
