<script>
import { GlPopover, GlButton, GlTooltipDirective } from '@gitlab/ui';
import $ from 'jquery';
import {
  keysFor,
  BOLD_TEXT,
  ITALIC_TEXT,
  STRIKETHROUGH_TEXT,
  LINK_TEXT,
  INDENT_LINE,
  OUTDENT_LINE,
} from '~/behaviors/shortcuts/keybindings';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getModifierKey } from '~/constants';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { updateText } from '~/lib/utils/text_markdown';
import ToolbarButton from './toolbar_button.vue';
import DrawioToolbarButton from './drawio_toolbar_button.vue';
import CommentTemplatesDropdown from './comment_templates_dropdown.vue';
import EditorModeSwitcher from './editor_mode_switcher.vue';

export default {
  components: {
    ToolbarButton,
    GlPopover,
    GlButton,
    DrawioToolbarButton,
    CommentTemplatesDropdown,
    AiActionsDropdown: () => import('ee_component/ai/components/ai_actions_dropdown.vue'),
    EditorModeSwitcher,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    newCommentTemplatePath: {
      default: null,
    },
    editorAiActions: { default: () => [] },
  },
  props: {
    previewMarkdown: {
      type: Boolean,
      required: true,
    },
    lineContent: {
      type: String,
      required: false,
      default: '',
    },
    canSuggest: {
      type: Boolean,
      required: false,
      default: true,
    },
    showSuggestPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
    suggestionStartIndex: {
      type: Number,
      required: false,
      default: 0,
    },
    enablePreview: {
      type: Boolean,
      required: false,
      default: true,
    },
    restrictedToolBarItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    uploadsPath: {
      type: String,
      required: false,
      default: '',
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    drawioEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    showContentEditorSwitcher: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      tag: '> ',
      suggestPopoverVisible: false,
      modifierKey: getModifierKey(),
    };
  },
  computed: {
    mdTable() {
      const header = s__('MarkdownEditor|header');
      const divider = '-'.repeat(header.length);
      const cell = ' '.repeat(header.length);

      return [
        `| ${header} | ${header} |`,
        `| ${divider} | ${divider} |`,
        `| ${cell} | ${cell} |`,
        `| ${cell} | ${cell} |`,
      ].join('\n');
    },
    mdSuggestion() {
      return [['```', `suggestion:-${this.suggestionStartIndex}+0`].join(''), `{text}`, '```'].join(
        '\n',
      );
    },
    mdCollapsibleSection() {
      const expandText = s__('MarkdownEditor|Click to expand');
      return [`<details><summary>${expandText}</summary>`, `{text}`, '</details>'].join('\n');
    },
    showEditorModeSwitcher() {
      return this.showContentEditorSwitcher && !this.previewMarkdown;
    },
  },
  watch: {
    showSuggestPopover() {
      this.updateSuggestPopoverVisibility();
    },
  },
  mounted() {
    $(document).on('markdown-preview:show.vue', this.showMarkdownPreview);
    $(document).on('markdown-preview:hide.vue', this.hideMarkdownPreview);

    this.updateSuggestPopoverVisibility();
  },
  beforeDestroy() {
    $(document).off('markdown-preview:show.vue', this.showMarkdownPreview);
    $(document).off('markdown-preview:hide.vue', this.hideMarkdownPreview);
  },
  methods: {
    async updateSuggestPopoverVisibility() {
      await this.$nextTick();

      this.suggestPopoverVisible = this.showSuggestPopover && this.canSuggest;
    },
    isValid(form) {
      return (
        !form ||
        (form.find('.js-vue-markdown-field').length && $(this.$el).closest('form')[0] === form[0])
      );
    },
    showMarkdownPreview(_, form) {
      if (!this.isValid(form)) return;

      this.$emit('showPreview');
    },
    hideMarkdownPreview(_, form) {
      if (!this.isValid(form)) return;

      this.$emit('hidePreview');
    },
    handleSuggestDismissed() {
      this.$emit('handleSuggestDismissed');
    },
    handleQuote() {
      const documentFragment = getSelectedFragment();

      if (!documentFragment || !documentFragment.textContent) {
        this.tag = '> ';
        return;
      }
      this.tag = '';

      const transformed = CopyAsGFM.transformGFMSelection(documentFragment);
      const area = this.$el.parentNode.querySelector('textarea');

      CopyAsGFM.nodeToGFM(transformed)
        .then((gfm) => {
          CopyAsGFM.insertPastedText(area, documentFragment.textContent, CopyAsGFM.quoted(gfm));
        })
        .catch(() => {});
    },
    handleAttachFile(e) {
      e.preventDefault();
      const $gfmForm = $(this.$el).closest('.gfm-form');
      const $gfmTextarea = $gfmForm.find('.js-gfm-input');

      $gfmForm.find('.div-dropzone').click();
      $gfmTextarea.focus();
    },
    insertIntoTextarea(text) {
      const textArea = this.$el.closest('.md-area')?.querySelector('textarea');
      if (textArea) {
        const generatedByText = `${text}\n***\n_${__('This comment was generated using AI')}_`;
        updateText({
          textArea,
          tag: generatedByText,
          cursorOffset: 0,
          wrap: false,
        });
      }
    },
    handleEditorModeChanged() {
      this.$emit('enableContentEditor');
    },
    switchPreview() {
      if (this.previewMarkdown) {
        this.hideMarkdownPreview();
      } else {
        this.showMarkdownPreview();
      }
    },
  },
  shortcuts: {
    bold: keysFor(BOLD_TEXT),
    italic: keysFor(ITALIC_TEXT),
    strikethrough: keysFor(STRIKETHROUGH_TEXT),
    link: keysFor(LINK_TEXT),
    indent: keysFor(INDENT_LINE),
    outdent: keysFor(OUTDENT_LINE),
  },
  i18n: {
    preview: __('Preview'),
    hidePreview: __('Continue editing'),
  },
};
</script>

<template>
  <div class="md-header gl-bg-gray-50 gl-px-2 gl-rounded-base gl-mx-2 gl-mt-2">
    <div
      class="gl-display-flex gl-align-items-center gl-flex-wrap"
      :class="{
        'gl-justify-content-end': previewMarkdown,
        'gl-justify-content-space-between': !previewMarkdown,
      }"
    >
      <div
        data-testid="md-header-toolbar"
        class="md-header-toolbar gl-display-flex gl-py-2 gl-flex-wrap"
        :class="{ 'gl-display-none!': previewMarkdown }"
      >
        <template v-if="canSuggest">
          <toolbar-button
            ref="suggestButton"
            :tag="mdSuggestion"
            :prepend="true"
            :button-title="__('Insert suggestion')"
            :cursor-offset="4"
            :tag-content="lineContent"
            icon="doc-code"
            data-qa-selector="suggestion_button"
            class="js-suggestion-btn"
            @click="handleSuggestDismissed"
          />
          <gl-popover
            v-if="suggestPopoverVisible"
            :target="$refs.suggestButton.$el"
            :css-classes="['diff-suggest-popover']"
            placement="bottom"
            :show="suggestPopoverVisible"
          >
            <strong>{{ __('New! Suggest changes directly') }}</strong>
            <p class="mb-2">
              {{
                __(
                  'Suggest code changes which can be immediately applied in one click. Try it out!',
                )
              }}
            </p>
            <gl-button
              variant="confirm"
              category="primary"
              size="small"
              data-qa-selector="dismiss_suggestion_popover_button"
              @click="handleSuggestDismissed"
            >
              {{ __('Got it') }}
            </gl-button>
          </gl-popover>
        </template>
        <ai-actions-dropdown
          v-if="editorAiActions.length"
          :actions="editorAiActions"
          @input="insertIntoTextarea"
        />
        <toolbar-button
          tag="**"
          :button-title="
            /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
            sprintf(s__('MarkdownEditor|Add bold text (%{modifierKey}B)'), {
              modifierKey,
            }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
          "
          :shortcuts="$options.shortcuts.bold"
          icon="bold"
        />
        <toolbar-button
          tag="_"
          :button-title="
            /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
            sprintf(s__('MarkdownEditor|Add italic text (%{modifierKey}I)'), {
              modifierKey,
            }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
          "
          :shortcuts="$options.shortcuts.italic"
          icon="italic"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('strikethrough')"
          tag="~~"
          :button-title="
            /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
            sprintf(s__('MarkdownEditor|Add strikethrough text (%{modifierKey}⇧X)'), {
              modifierKey /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */,
            })
          "
          :shortcuts="$options.shortcuts.strikethrough"
          icon="strikethrough"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('quote')"
          :prepend="true"
          :tag="tag"
          :button-title="__('Insert a quote')"
          icon="quote"
          @click="handleQuote"
        />
        <toolbar-button tag="`" tag-block="```" :button-title="__('Insert code')" icon="code" />
        <toolbar-button
          tag="[{text}](url)"
          tag-select="url"
          :button-title="
            /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
            sprintf(s__('MarkdownEditor|Add a link (%{modifierKey}K)'), {
              modifierKey,
            }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
          "
          :shortcuts="$options.shortcuts.link"
          icon="link"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('bullet-list')"
          :prepend="true"
          tag="- "
          :button-title="__('Add a bullet list')"
          icon="list-bulleted"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('numbered-list')"
          :prepend="true"
          tag="1. "
          :button-title="__('Add a numbered list')"
          icon="list-numbered"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('task-list')"
          :prepend="true"
          tag="- [ ] "
          :button-title="__('Add a checklist')"
          icon="list-task"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('indent')"
          class="gl-display-none"
          :button-title="
            /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
            sprintf(s__('MarkdownEditor|Indent line (%{modifierKey}])'), {
              modifierKey /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */,
            })
          "
          :shortcuts="$options.shortcuts.indent"
          command="indentLines"
          icon="list-indent"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('outdent')"
          class="gl-display-none"
          :button-title="
            /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
            sprintf(s__('MarkdownEditor|Outdent line (%{modifierKey}[)'), {
              modifierKey /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */,
            })
          "
          :shortcuts="$options.shortcuts.outdent"
          command="outdentLines"
          icon="list-outdent"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('collapsible-section')"
          :tag="mdCollapsibleSection"
          :prepend="true"
          tag-select="Click to expand"
          :button-title="__('Add a collapsible section')"
          icon="details-block"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('table')"
          :tag="mdTable"
          :prepend="true"
          :button-title="__('Add a table')"
          icon="table"
        />
        <gl-button
          v-if="!restrictedToolBarItems.includes('attach-file')"
          v-gl-tooltip
          :aria-label="__('Attach a file or image')"
          :title="__('Attach a file or image')"
          class="gl-mr-2"
          data-testid="button-attach-file"
          category="tertiary"
          icon="paperclip"
          size="small"
          @click="handleAttachFile"
        />
        <drawio-toolbar-button
          v-if="drawioEnabled"
          :uploads-path="uploadsPath"
          :markdown-preview-path="markdownPreviewPath"
        />
        <comment-templates-dropdown
          v-if="newCommentTemplatePath && glFeatures.savedReplies"
          :new-comment-template-path="newCommentTemplatePath"
        />
      </div>
      <div class="switch-preview gl-py-2 gl-display-flex gl-align-items-center gl-ml-auto">
        <editor-mode-switcher
          v-if="showEditorModeSwitcher"
          size="small"
          class="gl-mr-2"
          value="markdown"
          @input="handleEditorModeChanged"
        />
        <gl-button
          v-if="enablePreview"
          data-testid="preview-toggle"
          value="preview"
          :label="$options.i18n.previewTabTitle"
          class="js-md-preview-button gl-flex-direction-row-reverse gl-align-items-center gl-font-weight-normal!"
          size="small"
          category="tertiary"
          @click="switchPreview"
          >{{ previewMarkdown ? $options.i18n.hidePreview : $options.i18n.preview }}</gl-button
        >
        <gl-button
          v-if="!restrictedToolBarItems.includes('full-screen')"
          v-gl-tooltip
          :class="{ 'gl-display-none!': previewMarkdown }"
          class="js-zen-enter gl-ml-2"
          category="tertiary"
          icon="maximize"
          size="small"
          :title="__('Go full screen')"
          :prepend="true"
          :aria-label="__('Go full screen')"
        />
      </div>
    </div>
  </div>
</template>
