<script>
import { GlButton, GlLoadingIcon, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import EditorModeSwitcher from './editor_mode_switcher.vue';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    GlSprintf,
    GlIcon,
    EditorModeSwitcher,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    markdownDocsPath: {
      type: String,
      required: true,
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
    showEditorModeSwitcher() {
      return this.showContentEditorSwitcher;
    },
  },
  methods: {
    handleEditorModeChanged() {
      this.$emit('enableContentEditor');
    },
  },
};
</script>

<template>
  <div
    v-if="showCommentToolBar"
    class="comment-toolbar gl-display-flex gl-flex-direction-row gl-mx-2 gl-mb-2 gl-px-2 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
    :class="
      showContentEditorSwitcher
        ? 'gl-bg-gray-10 gl-justify-content-space-between'
        : 'gl-justify-content-end'
    "
  >
    <editor-mode-switcher
      v-if="showEditorModeSwitcher"
      size="small"
      value="markdown"
      @input="handleEditorModeChanged"
    />
    <div>
      <div class="toolbar-text gl-font-sm">
        <template v-if="markdownDocsPath">
          <gl-button
            v-gl-tooltip
            icon="markdown-mark"
            :href="markdownDocsPath"
            target="_blank"
            category="tertiary"
            size="small"
            title="Markdown is supported"
          />
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
  </div>
</template>
