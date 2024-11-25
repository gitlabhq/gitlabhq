<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlLoadingIcon, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { updateText } from '~/lib/utils/text_markdown';
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
    insertIntoTextarea(...lines) {
      const text = lines.join('\n');
      const textArea = this.$el.closest('.md-area')?.querySelector('textarea');
      if (textArea && !textArea.value) {
        updateText({
          textArea,
          tag: text,
          cursorOffset: 0,
          wrap: false,
        });
      }
    },
  },
};
</script>

<template>
  <div
    v-if="showCommentToolBar"
    class="comment-toolbar gl-flex gl-flex-row gl-rounded-b-base gl-px-2"
    :class="
      showContentEditorSwitcher
        ? 'gl-border-t gl-items-center gl-justify-between gl-border-default'
        : 'gl-my-2 gl-justify-end'
    "
  >
    <editor-mode-switcher
      v-if="showEditorModeSwitcher"
      size="small"
      value="markdown"
      @switch="$emit('enableContentEditor')"
    />
    <div class="gl-flex">
      <div v-if="canAttachFile" class="uploading-container gl-mr-3 gl-text-sm gl-leading-32">
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
                class="retry-uploading-link gl-align-baseline !gl-text-sm"
              >
                {{ content }}
              </gl-button>
            </template>
            <template #newFileButton="{ content }">
              <gl-button
                variant="link"
                category="primary"
                class="markdown-selector attach-new-file gl-align-baseline !gl-text-sm"
              >
                {{ content }}
              </gl-button>
            </template>
          </gl-sprintf>
        </span>
        <gl-button
          variant="link"
          category="primary"
          class="button-cancel-uploading-files hide gl-align-baseline !gl-text-sm"
        >
          {{ __('Cancel') }}
        </gl-button>
      </div>
      <slot name="toolbar"></slot>
      <gl-button
        v-if="markdownDocsPath"
        v-gl-tooltip
        icon="markdown-mark"
        :href="markdownDocsPath"
        target="_blank"
        category="tertiary"
        size="small"
        :title="__('Markdown is supported')"
        :aria-label="__('Markdown is supported')"
        class="!gl-px-3"
      />
    </div>
  </div>
</template>
