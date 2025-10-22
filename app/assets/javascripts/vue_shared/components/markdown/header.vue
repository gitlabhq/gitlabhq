<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlPopover, GlButton, GlTooltipDirective, GlFormInput } from '@gitlab/ui';
import { GL_COLOR_ORANGE_50, GL_COLOR_ORANGE_200 } from '@gitlab/ui/src/tokens/build/js/tokens';
import $ from 'jquery';
import { escapeRegExp } from 'lodash';
import {
  keysFor,
  BOLD_TEXT,
  ITALIC_TEXT,
  STRIKETHROUGH_TEXT,
  LINK_TEXT,
  INDENT_LINE,
  OUTDENT_LINE,
  FIND_AND_REPLACE,
} from '~/behaviors/shortcuts/keybindings';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getModifierKey } from '~/constants';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__, __, sprintf } from '~/locale';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { updateText, repeatCodeBackticks } from '~/lib/utils/text_markdown';
import ToolbarTableButton from '~/content_editor/components/toolbar_table_button.vue';
import ToolbarButton from './toolbar_button.vue';
import DrawioToolbarButton from './drawio_toolbar_button.vue';
import CommentTemplatesModal from './comment_templates_modal.vue';
import HeaderDivider from './header_divider.vue';
import ToolbarMoreDropdown from './toolbar_more_dropdown.vue';

export default {
  findAndReplace: {
    highlightColor: GL_COLOR_ORANGE_50,
    highlightColorActive: GL_COLOR_ORANGE_200,
    highlightClass: 'js-highlight',
    highlightClassActive: 'js-highlight-active',
  },

  components: {
    ToolbarButton,
    ToolbarTableButton,
    GlPopover,
    GlButton,
    GlFormInput,
    DrawioToolbarButton,
    CommentTemplatesModal,
    AiActionsDropdown: () => import('ee_component/ai/components/ai_actions_dropdown.vue'),
    HeaderDivider,
    SummarizeCodeChanges: () =>
      import('ee_component/merge_requests/components/summarize_code_changes.vue'),
    ToolbarMoreDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    newCommentTemplatePaths: {
      default: () => [],
    },
    mrGeneratedContent: { default: null },
    canSummarizeChanges: { default: false },
    summarizeDisabledReason: { default: null },
    canUseComposer: { default: false },
    legacyEditorAiActions: { default: () => [] },
  },
  props: {
    editorAiActions: {
      type: Array,
      required: false,
      default: () => [],
    },
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
    newCommentTemplatePathsProp: {
      type: Array,
      required: false,
      default: () => [],
    },
    drawioEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    supportsQuickActions: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const modifierKey = getModifierKey();

    return {
      tag: '> ',
      suggestPopoverVisible: false,
      findAndReplace: {
        find: '',
        replace: '',
        shouldShowBar: false,
        totalMatchCount: 0,
        highlightedMatchIndex: 0,
      },
      modifierKey,
      shiftKey: modifierKey === '⌘' ? '⇧' : 'Shift+',
    };
  },
  computed: {
    aiActions() {
      if (this.editorAiActions.length > 0) {
        return this.editorAiActions;
      }
      return this.legacyEditorAiActions;
    },
    commentTemplatePaths() {
      return this.newCommentTemplatePaths.length > 0
        ? this.newCommentTemplatePaths
        : this.newCommentTemplatePathsProp;
    },
    mdSuggestion() {
      const codeblockChars = repeatCodeBackticks(this.lineContent);

      return [
        `${codeblockChars}suggestion:-${this.suggestionStartIndex}+0`,
        `{text}`,
        codeblockChars,
      ].join('\n');
    },
    hideDividerBeforeTable() {
      return (
        this.previewMarkdown ||
        (this.restrictedToolBarItems.includes('table') &&
          this.restrictedToolBarItems.includes('attach-file') &&
          !this.drawioEnabled &&
          !this.supportsQuickActions &&
          !this.commentTemplatePaths.length)
      );
    },
    showFindAndReplaceButton() {
      return (
        this.glFeatures.findAndReplace && !this.restrictedToolBarItems.includes('find-and-replace')
      );
    },
    findAndReplace_MatchCountText() {
      if (!this.findAndReplace.totalMatchCount) {
        return s__('MarkdownEditor|No records');
      }

      return sprintf(s__('MarkdownEditor|%{currentHighlight} of %{totalHighlights}'), {
        currentHighlight: this.findAndReplace.highlightedMatchIndex,
        totalHighlights: this.findAndReplace.totalMatchCount,
      });
    },
    previewToggleTooltip() {
      return sprintf(
        this.previewMarkdown
          ? s__('MarkdownEditor|Continue editing (%{shiftKey}%{modifierKey}P)')
          : s__('MarkdownEditor|Preview (%{shiftKey}%{modifierKey}P)'),
        {
          shiftKey: this.shiftKey,
          modifierKey: this.modifierKey,
        },
      );
    },
    indentButtonText() {
      return sprintf(s__('MarkdownEditor|Indent line (%{modifierKey}])'), {
        modifierKey: this.modifierKey,
      });
    },
    outdentButtonText() {
      return sprintf(s__('MarkdownEditor|Outdent line (%{modifierKey}[)'), {
        modifierKey: this.modifierKey,
      });
    },
    boldButtonText() {
      return sprintf(s__('MarkdownEditor|Add bold text (%{modifierKey}B)'), {
        modifierKey: this.modifierKey,
      });
    },
    italicButtonText() {
      return sprintf(s__('MarkdownEditor|Add italic text (%{modifierKey}I)'), {
        modifierKey: this.modifierKey,
      });
    },
    strikethroughButtonText() {
      return sprintf(s__('MarkdownEditor|Add strikethrough text (%{modifierKey}%{shiftKey}X)'), {
        modifierKey: this.modifierKey,
        shiftKey: this.shiftKey,
      });
    },
    linkButtonText() {
      return sprintf(s__('MarkdownEditor|Add a link (%{modifierKey}K)'), {
        modifierKey: this.modifierKey,
      });
    },
  },
  watch: {
    showSuggestPopover() {
      this.updateSuggestPopoverVisibility();
    },
    'findAndReplace.highlightedMatchIndex': {
      handler(newValue) {
        const options = this.$options.findAndReplace;
        const previousActive = this.cloneDiv.querySelector(`.${options.highlightClassActive}`);

        if (previousActive) {
          previousActive.classList.remove(options.highlightClassActive);
          previousActive.style.backgroundColor = options.highlightColor;
        }

        const newActive = this.cloneDiv
          .querySelectorAll(`.${options.highlightClass}`)
          .item(newValue - 1);

        if (newActive) {
          newActive.classList.add(options.highlightClassActive);
          newActive.style.backgroundColor = options.highlightColorActive;
        }
      },
    },
  },
  mounted() {
    $(document).on('markdown-preview:show.vue', this.showMarkdownPreview);
    $(document).on('markdown-preview:hide.vue', this.hideMarkdownPreview);
    $(document).on('markdown-editor:find-and-replace:show', this.findAndReplace_show);

    this.updateSuggestPopoverVisibility();
  },
  beforeDestroy() {
    $(document).off('markdown-preview:show.vue', this.showMarkdownPreview);
    $(document).off('markdown-preview:hide.vue', this.hideMarkdownPreview);
    $(document).off('markdown-editor:find-and-replace:show', this.findAndReplace_show);
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
    getCurrentTextArea() {
      return this.$el.closest('.md-area')?.querySelector('textarea');
    },
    insertIntoTextarea(text) {
      const textArea = this.getCurrentTextArea();

      if (textArea) {
        updateText({
          textArea,
          tag: text,
          cursorOffset: 0,
          wrap: false,
        });
      }
    },
    insertTable({ rows, cols }) {
      const headerContent = s__('MarkdownEditor|header');
      const dividerContent = '-'.repeat(headerContent.length);
      const cellContent = ' '.repeat(headerContent.length);

      const table = [
        `|${` ${headerContent} |`.repeat(cols)}`,
        `|${` ${dividerContent} |`.repeat(cols)}`,
      ];
      const createRow = (content, colCount) => `|${` ${content} |`.repeat(colCount)}`;
      for (let i = 0; i < rows; i += 1) {
        table.push(createRow(cellContent, cols));
      }

      this.insertIntoTextarea(table.join('\n'));
    },
    replaceTextarea(text) {
      const { description, descriptionForSha } = this.$options.i18n;
      const headSha = document.getElementById('merge_request_diff_head_sha').value;
      const addendum = headSha
        ? sprintf(descriptionForSha, { revision: truncateSha(headSha) })
        : description;

      if (this.mrGeneratedContent) {
        this.mrGeneratedContent.setGeneratedContent(`${text}\n\n---\n\n_${addendum}_`);
        this.mrGeneratedContent.showWarning();
      }
    },
    switchPreview() {
      if (this.previewMarkdown) {
        this.hideMarkdownPreview();
      } else {
        this.showMarkdownPreview();
      }
    },
    insertAIAction(text) {
      this.insertIntoTextarea(`${text}\n\n---\n\n_${__('This comment was generated by AI')}_`);
    },
    insertSavedReply(savedReply) {
      this.insertIntoTextarea(savedReply);

      setTimeout(() => {
        this.$el.closest('.md-area')?.querySelector('textarea')?.focus();
      }, 500);
    },
    findAndReplace_show(_, form) {
      if (!this.isValid(form)) return;

      this.findAndReplace.shouldShowBar = true;
    },
    findAndReplace_close() {
      this.findAndReplace.shouldShowBar = false;
      this.getCurrentTextArea()?.removeEventListener('scroll', this.findAndReplace_syncScroll);
      this.cloneDiv?.parentElement.removeChild(this.cloneDiv);
      this.cloneDiv = undefined;
    },
    findAndReplace_handleKeyDown(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
      } else if (e.key === 'Escape') {
        this.findAndReplace_close();
      }
    },
    findAndReplace_handleKeyUp(e) {
      if (e.key === 'Enter') {
        this.findAndReplace_handleNext();
      } else {
        this.findAndReplace_highlightMatchingText(e.target.value);
      }
    },
    findAndReplace_syncScroll() {
      const textArea = this.getCurrentTextArea();
      this.cloneDiv.scrollTop = textArea.scrollTop;
    },
    findAndReplace_safeReplace(textArea, textToFind) {
      this.findAndReplace.totalMatchCount = 0;
      this.findAndReplace.highlightedMatchIndex = 0;

      if (!textToFind) {
        return;
      }

      // RegExp.escape is not available in jest environment and some older browsers
      const escapedText = (RegExp.escape || escapeRegExp).call(null, textToFind);

      // Regex with global modifier maintains state between calls, causing inconsistent behaviour.
      // So we have to test against a regexp without the global flag when matching segments.
      const regexWithoutG = new RegExp(escapedText, 'gi');

      const segments = textArea.value.split(new RegExp(`(${escapedText})`, 'gi'));
      const options = this.$options.findAndReplace;

      // Clear previous contents
      this.cloneDiv.innerHTML = '';
      let counter = 0;

      segments.forEach((segment) => {
        // If the segment matches the text we're highlighting
        if (regexWithoutG.test(segment)) {
          const span = document.createElement('span');
          span.classList.add(options.highlightClass);
          span.style.backgroundColor = options.highlightColor;
          span.style.display = 'inline-block';
          span.textContent = segment; // Use textContent for safe text insertion

          // Highlight first match
          if (counter === 0) {
            span.classList.add(options.highlightClassActive);
            span.style.backgroundColor = options.highlightColorActive;
          }

          this.cloneDiv.appendChild(span);
          this.findAndReplace.totalMatchCount += 1;
          counter += 1;
        } else {
          // Otherwise, just append the plain text
          const textNode = document.createTextNode(segment);
          this.cloneDiv.appendChild(textNode);
        }
      });

      if (this.findAndReplace.totalMatchCount > 0) {
        this.findAndReplace.highlightedMatchIndex = 1;
      }
    },
    async findAndReplace_highlightMatchingText(text) {
      const textArea = this.getCurrentTextArea();

      if (!textArea) {
        return;
      }

      // Make sure we got the right zIndex
      textArea.style.position = 'relative';
      textArea.style.zIndex = 2;

      await this.findAndReplace_attachCloneDivIfNotExists(textArea);

      this.findAndReplace_safeReplace(textArea, text);
    },
    async findAndReplace_attachCloneDivIfNotExists(textArea) {
      if (this.cloneDiv) {
        return;
      }

      this.cloneDiv = document.createElement('div');
      this.cloneDiv.dataset.testid = 'find-and-replace-clone';
      this.cloneDiv.textContent = textArea.value;

      const computedStyle = window.getComputedStyle(textArea);
      const propsToCopy = [
        'width',
        'height',
        'padding',
        'border',
        'font-family',
        'font-size',
        'line-height',
        'background-color',
        'color',
        'overflow',
        'white-space',
        'word-wrap',
        'resize',
        'margin',
      ];

      propsToCopy.forEach((prop) => {
        this.cloneDiv.style[prop] = computedStyle[prop];
      });

      // Additional required styles for div
      this.cloneDiv.style.whiteSpace = 'pre-wrap';
      this.cloneDiv.style.overflowY = 'auto';
      this.cloneDiv.style.position = 'absolute';
      this.cloneDiv.style.zIndex = 1;
      this.cloneDiv.style.color = 'transparent';

      textArea.addEventListener('scroll', this.findAndReplace_syncScroll);

      textArea.parentElement.insertBefore(this.cloneDiv, textArea);

      await this.$nextTick();

      // Required to align the clone div
      this.cloneDiv.scrollTop = textArea.scrollTop;
    },
    findAndReplace_handlePrev() {
      this.findAndReplace.highlightedMatchIndex -= 1;

      if (this.findAndReplace.highlightedMatchIndex <= 0) {
        this.findAndReplace.highlightedMatchIndex = this.findAndReplace.totalMatchCount;
      }
    },
    findAndReplace_handleNext() {
      this.findAndReplace.highlightedMatchIndex += 1;

      if (this.findAndReplace.highlightedMatchIndex > this.findAndReplace.totalMatchCount) {
        this.findAndReplace.highlightedMatchIndex = 1;
      }
    },
    skipToInput() {
      this.$el.closest('.md-area')?.querySelector('textarea')?.focus();
    },
  },
  shortcuts: {
    bold: keysFor(BOLD_TEXT),
    italic: keysFor(ITALIC_TEXT),
    strikethrough: keysFor(STRIKETHROUGH_TEXT),
    link: keysFor(LINK_TEXT),
    indent: keysFor(INDENT_LINE),
    outdent: keysFor(OUTDENT_LINE),
    findAndReplace: keysFor(FIND_AND_REPLACE),
  },
  i18n: {
    comment: __('This comment was generated by AI'),
    description: s__('MergeRequest|This description was generated using AI'),
    descriptionForSha: s__(
      'MergeRequest|This description was generated for revision %{revision} using AI',
    ),
    hidePreview: __('Continue editing'),
    preview: __('Preview'),
    editorToolbar: __('Editor toolbar'),
  },
};
</script>

<template>
  <div
    class="md-header gl-border-b gl-z-2 gl-rounded-lg gl-rounded-b-none gl-border-default gl-px-3"
    :class="{ 'md-header-preview': previewMarkdown }"
  >
    <gl-button
      v-if="!previewMarkdown"
      data-testid="skip-to-input"
      size="small"
      category="primary"
      variant="confirm"
      class="gl-sr-only !gl-absolute gl-left-3 gl-top-3 focus:gl-not-sr-only"
      @click="skipToInput"
      >{{ __('Skip to input') }}</gl-button
    >
    <div class="gl-flex gl-flex-wrap gl-items-center">
      <div
        data-testid="md-header-toolbar"
        class="md-header-toolbar gl-flex gl-grow gl-items-start gl-gap-y-2 gl-py-3"
      >
        <div
          class="gl-flex gl-flex-wrap gl-gap-y-2"
          role="toolbar"
          :aria-label="$options.i18n.editorToolbar"
        >
          <gl-button
            v-if="enablePreview"
            v-gl-tooltip
            data-testid="preview-toggle"
            :value="previewMarkdown ? 'preview' : 'edit'"
            :title="previewToggleTooltip"
            :label="$options.i18n.previewTabTitle"
            class="js-md-preview-button gl-flex-row-reverse gl-items-center !gl-font-normal"
            size="small"
            category="tertiary"
            @click="switchPreview"
            >{{ previewMarkdown ? $options.i18n.hidePreview : $options.i18n.preview }}</gl-button
          >
          <template v-if="!previewMarkdown && canSuggest">
            <div class="gl-flex gl-gap-y-2">
              <header-divider v-if="!previewMarkdown" />
              <toolbar-button
                ref="suggestButton"
                :tag="mdSuggestion"
                :prepend="true"
                :button-title="s__('MarkdownEditor|Insert suggestion')"
                :cursor-offset="4"
                :tag-content="lineContent"
                tracking-property="codeSuggestion"
                icon="doc-code"
                data-testid="suggestion-button"
                class="js-suggestion-btn"
                @click="handleSuggestDismissed"
              />
              <gl-popover
                v-if="suggestPopoverVisible"
                :target="$refs.suggestButton.$el"
                :css-classes="['diff-suggest-popover']"
                placement="bottom"
                :show="suggestPopoverVisible"
                triggers=""
              >
                <strong>{{ s__('MarkdownEditor|New! Suggest changes directly') }}</strong>
                <p class="!gl-mb-3">
                  {{
                    s__(
                      'MarkdownEditor|Suggest code changes which can be immediately applied in one click. Try it out!',
                    )
                  }}
                </p>
                <gl-button
                  variant="confirm"
                  category="primary"
                  size="small"
                  data-testid="dismiss-suggestion-popover-button"
                  @click="handleSuggestDismissed"
                >
                  {{ __('Got it') }}
                </gl-button>
              </gl-popover>
            </div>
          </template>
          <div class="gl-flex gl-gap-y-2">
            <div v-if="!previewMarkdown && aiActions.length" class="gl-flex gl-gap-y-2">
              <header-divider v-if="!previewMarkdown" />
              <ai-actions-dropdown
                :actions="aiActions"
                @input="insertAIAction"
                @replace="replaceTextarea"
              />
            </div>
            <header-divider v-if="enablePreview && !previewMarkdown" />
          </div>
          <toolbar-button
            v-show="!previewMarkdown"
            tag="**"
            :button-title="boldButtonText"
            :shortcuts="$options.shortcuts.bold"
            icon="bold"
            tracking-property="bold"
          />
          <toolbar-button
            v-show="!previewMarkdown"
            tag="_"
            :button-title="italicButtonText"
            :shortcuts="$options.shortcuts.italic"
            icon="italic"
            tracking-property="italic"
          />
          <div class="gl-flex gl-gap-y-2">
            <toolbar-button
              v-if="!restrictedToolBarItems.includes('strikethrough')"
              v-show="!previewMarkdown"
              tag="~~"
              :button-title="strikethroughButtonText"
              :shortcuts="$options.shortcuts.strikethrough"
              icon="strikethrough"
              tracking-property="strike"
            />
            <header-divider v-if="!previewMarkdown" />
          </div>
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('quote')"
            v-show="!previewMarkdown"
            :prepend="true"
            :tag="tag"
            :button-title="s__('MarkdownEditor|Insert a quote')"
            icon="quote"
            tracking-property="blockquote"
            @click="handleQuote"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('code')"
            v-show="!previewMarkdown"
            tag="`"
            tag-block="```"
            :button-title="s__('MarkdownEditor|Insert code')"
            icon="code"
            tracking-property="code"
          />
          <toolbar-button
            v-show="!previewMarkdown"
            tag="[{text}](url)"
            tag-select="url"
            :button-title="linkButtonText"
            :shortcuts="$options.shortcuts.link"
            icon="link"
            tracking-property="link"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('bullet-list')"
            v-show="!previewMarkdown"
            :prepend="true"
            tag="- "
            :button-title="s__('MarkdownEditor|Add a bullet list')"
            icon="list-bulleted"
            tracking-property="bulletList"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('numbered-list')"
            v-show="!previewMarkdown"
            :prepend="true"
            tag="1. "
            :button-title="s__('MarkdownEditor|Add a numbered list')"
            icon="list-numbered"
            tracking-property="orderedList"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('task-list')"
            v-show="!previewMarkdown"
            :prepend="true"
            tag="- [ ] "
            :button-title="s__('MarkdownEditor|Add a checklist')"
            icon="list-task"
            tracking-property="taskList"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('indent')"
            v-show="!previewMarkdown"
            class="gl-hidden"
            :button-title="indentButtonText"
            :shortcuts="$options.shortcuts.indent"
            command="indentLines"
            icon="list-indent"
            tracking-property="indent"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('outdent')"
            v-show="!previewMarkdown"
            class="gl-hidden"
            :button-title="outdentButtonText"
            :shortcuts="$options.shortcuts.outdent"
            command="outdentLines"
            icon="list-outdent"
            tracking-property="outdent"
          />
          <div class="gl-flex gl-gap-y-2">
            <header-divider v-if="!hideDividerBeforeTable" />
            <toolbar-table-button
              v-show="!previewMarkdown"
              v-if="!restrictedToolBarItems.includes('table')"
              @insert-table="insertTable"
            />
          </div>
          <!--
            The attach file button's click behavior is added by
            dropzone_input.js.
          -->
          <toolbar-button
            v-show="!previewMarkdown && !restrictedToolBarItems.includes('attach-file')"
            data-testid="button-attach-file"
            data-button-type="attach-file"
            :button-title="s__('MarkdownEditor|Attach a file or image')"
            icon="paperclip"
            class="gl-mr-2"
            tracking-property="upload"
          />
          <drawio-toolbar-button
            v-if="!previewMarkdown && drawioEnabled"
            :uploads-path="uploadsPath"
            :markdown-preview-path="markdownPreviewPath"
          />
          <!-- TODO Add icon and trigger functionality from here -->
          <toolbar-button
            v-if="supportsQuickActions"
            v-show="!previewMarkdown"
            :prepend="true"
            tag="/"
            :button-title="s__('MarkdownEditor|Add a quick action')"
            icon="quick-actions"
            tracking-property="quickAction"
          />
          <div v-if="!previewMarkdown" class="gl-flex gl-gap-y-2">
            <header-divider />
            <comment-templates-modal
              v-if="!previewMarkdown && commentTemplatePaths.length"
              :new-comment-template-paths="commentTemplatePaths"
              @select="insertSavedReply"
            />
            <toolbar-more-dropdown />
          </div>
          <template v-if="!previewMarkdown && canSummarizeChanges && !canUseComposer">
            <header-divider />
            <summarize-code-changes :disabled-reason="summarizeDisabledReason" />
          </template>
          <slot v-if="!previewMarkdown" name="header-buttons"></slot>
        </div>
        <div v-if="!previewMarkdown" class="full-screen gl-flex gl-grow gl-justify-end">
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('full-screen')"
            class="js-zen-enter !gl-mr-0"
            icon="maximize"
            :button-title="s__('MarkdownEditor|Go full screen')"
            :prepend="true"
            tracking-property="fullScreen"
          />
        </div>
        <toolbar-button
          v-if="showFindAndReplaceButton"
          v-show="!previewMarkdown"
          class="gl-hidden"
          :button-title="s__('MarkdownEditor|Find and replace')"
          :shortcuts="$options.shortcuts.findAndReplace"
          icon="retry"
        />
      </div>
    </div>
    <div
      v-if="findAndReplace.shouldShowBar"
      class="gl-border gl-absolute gl-right-0 gl-z-3 gl-flex gl-w-34 gl-items-center gl-rounded-bl-base gl-border-r-0 gl-bg-section gl-p-3 gl-shadow-sm"
      data-testid="find-and-replace"
    >
      <gl-form-input
        v-model="findAndReplace.find"
        :placeholder="s__('MarkdownEditor|Find')"
        autofocus
        data-testid="find-btn"
        @keydown="findAndReplace_handleKeyDown"
        @keyup="findAndReplace_handleKeyUp"
      />
      <div class="gl-ml-4 gl-min-w-12 gl-whitespace-nowrap">
        {{ findAndReplace_MatchCountText }}
      </div>
      <div class="gl-ml-2 gl-flex gl-items-center">
        <gl-button
          category="tertiary"
          icon="arrow-up"
          size="small"
          data-testid="find-prev"
          :aria-label="s__('MarkdownEditor|Find previous')"
          @click="findAndReplace_handlePrev"
        />
        <gl-button
          category="tertiary"
          icon="arrow-down"
          size="small"
          data-testid="find-next"
          :aria-label="s__('MarkdownEditor|Find next')"
          @click="findAndReplace_handleNext"
        />
      </div>
      <gl-button
        category="tertiary"
        icon="close"
        size="small"
        data-testid="find-and-replace-close"
        :aria-label="s__('MarkdownEditor|Close find and replace bar')"
        @click="findAndReplace_close"
      />
    </div>
  </div>
</template>
