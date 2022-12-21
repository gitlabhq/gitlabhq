<script>
import { GlButton, GlLink, GlLoadingIcon, GlSprintf, GlIcon } from '@gitlab/ui';
import EditorModeDropdown from './editor_mode_dropdown.vue';

export default {
  components: {
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlIcon,
    EditorModeDropdown,
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
    showContentEditorSwitcher: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasQuickActionsDocsPath() {
      return this.quickActionsDocsPath !== '';
    },
  },
  methods: {
    handleEditorModeChanged(mode) {
      if (mode === 'richText') {
        this.$emit('enableContentEditor');
      }
    },
  },
};
</script>

<template>
  <div v-if="showCommentToolBar" class="comment-toolbar clearfix">
    <div class="toolbar-text">
      <template v-if="!hasQuickActionsDocsPath && markdownDocsPath">
        <gl-sprintf
          :message="
            s__('MarkdownToolbar|Supports %{markdownDocsLinkStart}Markdown%{markdownDocsLinkEnd}')
          "
        >
          <template #markdownDocsLink="{ content }">
            <gl-link :href="markdownDocsPath" target="_blank">{{ content }}</gl-link>
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
            <gl-link :href="markdownDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
          <template #keyboard="{ content }">
            <kbd>{{ content }}</kbd>
          </template>
          <template #quickActionsDocsLink="{ content }">
            <gl-link :href="quickActionsDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </div>
    <span v-if="canAttachFile" class="uploading-container gl-line-height-32">
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
              class="retry-uploading-link gl-vertical-align-baseline"
            >
              {{ content }}
            </gl-button>
          </template>
          <template #newFileButton="{ content }">
            <gl-button
              variant="link"
              category="primary"
              class="markdown-selector attach-new-file gl-vertical-align-baseline"
            >
              {{ content }}
            </gl-button>
          </template>
        </gl-sprintf>
      </span>
      <gl-button
        variant="link"
        category="primary"
        class="button-cancel-uploading-files gl-vertical-align-baseline hide"
      >
        {{ __('Cancel') }}
      </gl-button>
    </span>
    <editor-mode-dropdown
      v-if="showContentEditorSwitcher"
      size="small"
      class="gl-float-right gl-line-height-28 gl-display-block"
      value="markdown"
      @input="handleEditorModeChanged"
    />
  </div>
</template>
