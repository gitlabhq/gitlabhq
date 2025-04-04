<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlPopover, GlButton, GlTooltipDirective, GlFormInput } from '@gitlab/ui';
import $ from 'jquery';
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

export default {
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
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    newCommentTemplatePaths: {
      default: () => [],
    },
    editorAiActions: { default: () => [] },
    mrGeneratedContent: { default: null },
    canSummarizeChanges: { default: false },
    canUseComposer: { default: false },
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
      },
      modifierKey,
      shiftKey: modifierKey === '⌘' ? '⇧' : 'Shift+',
    };
  },
  computed: {
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
    mdCollapsibleSection() {
      const expandText = s__('MarkdownEditor|Click to expand');
      return [`<details><summary>${expandText}</summary>`, `{text}`, '</details>'].join('\n');
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
  },
  watch: {
    showSuggestPopover() {
      this.updateSuggestPopoverVisibility();
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
    findAndReplace_handleKeyDown(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
      } else if (e.key === 'Escape') {
        this.findAndReplace.shouldShowBar = false;
        this.getCurrentTextArea()?.removeEventListener('scroll', this.findAndReplace_syncScroll);
        this.cloneDiv?.parentElement.removeChild(this.cloneDiv);
        this.cloneDiv = undefined;
      }
    },
    findAndReplace_handleKeyUp(e) {
      this.findAndReplace_highlightMatchingText(e.target.value);
    },
    findAndReplace_syncScroll() {
      const textArea = this.getCurrentTextArea();
      this.cloneDiv.scrollTop = textArea.scrollTop;
    },
    findAndReplace_safeReplace(textArea, textToFind) {
      const regex = new RegExp(`(${textToFind})`, 'g');
      const segments = textArea.value.split(regex);

      // Clear previous contents
      this.cloneDiv.innerHTML = '';

      segments.forEach((segment) => {
        // If the segment matches the text we're highlighting
        if (segment === textToFind) {
          const span = document.createElement('span');
          span.classList.add('js-highlight');
          span.style.backgroundColor = 'orange';
          span.style.display = 'inline-block';
          span.textContent = segment; // Use textContent for safe text insertion
          this.cloneDiv.appendChild(span);
        } else {
          // Otherwise, just append the plain text
          const textNode = document.createTextNode(segment);
          this.cloneDiv.appendChild(textNode);
        }
      });
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
            data-testid="preview-toggle"
            :value="previewMarkdown ? 'preview' : 'edit'"
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
                :button-title="__('Insert suggestion')"
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
                  data-testid="dismiss-suggestion-popover-button"
                  @click="handleSuggestDismissed"
                >
                  {{ __('Got it') }}
                </gl-button>
              </gl-popover>
            </div>
          </template>
          <div class="gl-flex gl-gap-y-2">
            <div v-if="!previewMarkdown && editorAiActions.length" class="gl-flex gl-gap-y-2">
              <header-divider v-if="!previewMarkdown" />
              <ai-actions-dropdown
                :actions="editorAiActions"
                @input="insertAIAction"
                @replace="replaceTextarea"
              />
            </div>
            <header-divider v-if="enablePreview && !previewMarkdown" />
          </div>
          <toolbar-button
            v-show="!previewMarkdown"
            tag="**"
            :button-title="
              /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
              sprintf(s__('MarkdownEditor|Add bold text (%{modifierKey}B)'), {
                modifierKey,
              }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
            "
            :shortcuts="$options.shortcuts.bold"
            icon="bold"
            tracking-property="bold"
          />
          <toolbar-button
            v-show="!previewMarkdown"
            tag="_"
            :button-title="
              /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
              sprintf(s__('MarkdownEditor|Add italic text (%{modifierKey}I)'), {
                modifierKey,
              }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
            "
            :shortcuts="$options.shortcuts.italic"
            icon="italic"
            tracking-property="italic"
          />
          <div class="gl-flex gl-gap-y-2">
            <toolbar-button
              v-if="!restrictedToolBarItems.includes('strikethrough')"
              v-show="!previewMarkdown"
              tag="~~"
              :button-title="
                /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
                sprintf(s__('MarkdownEditor|Add strikethrough text (%{modifierKey}%{shiftKey}X)'), {
                  modifierKey,
                  shiftKey /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */,
                })
              "
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
            :button-title="__('Insert a quote')"
            icon="quote"
            tracking-property="blockquote"
            @click="handleQuote"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('code')"
            v-show="!previewMarkdown"
            tag="`"
            tag-block="```"
            :button-title="__('Insert code')"
            icon="code"
            tracking-property="code"
          />
          <toolbar-button
            v-show="!previewMarkdown"
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
            tracking-property="link"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('bullet-list')"
            v-show="!previewMarkdown"
            :prepend="true"
            tag="- "
            :button-title="__('Add a bullet list')"
            icon="list-bulleted"
            tracking-property="bulletList"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('numbered-list')"
            v-show="!previewMarkdown"
            :prepend="true"
            tag="1. "
            :button-title="__('Add a numbered list')"
            icon="list-numbered"
            tracking-property="orderedList"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('task-list')"
            v-show="!previewMarkdown"
            :prepend="true"
            tag="- [ ] "
            :button-title="__('Add a checklist')"
            icon="list-task"
            tracking-property="taskList"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('indent')"
            v-show="!previewMarkdown"
            class="gl-hidden"
            :button-title="
              /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
              sprintf(s__('MarkdownEditor|Indent line (%{modifierKey}])'), {
                modifierKey /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */,
              })
            "
            :shortcuts="$options.shortcuts.indent"
            command="indentLines"
            icon="list-indent"
            tracking-property="indent"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('outdent')"
            v-show="!previewMarkdown"
            class="gl-hidden"
            :button-title="
              /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
              sprintf(s__('MarkdownEditor|Outdent line (%{modifierKey}[)'), {
                modifierKey /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */,
              })
            "
            :shortcuts="$options.shortcuts.outdent"
            command="outdentLines"
            icon="list-outdent"
            tracking-property="outdent"
          />
          <div class="gl-flex gl-gap-y-2">
            <toolbar-button
              v-if="!restrictedToolBarItems.includes('collapsible-section')"
              v-show="!previewMarkdown"
              :tag="mdCollapsibleSection"
              :prepend="true"
              tag-select="Click to expand"
              :button-title="__('Add a collapsible section')"
              icon="details-block"
              tracking-property="details"
            />
            <header-divider v-if="!hideDividerBeforeTable" />
          </div>
          <toolbar-table-button
            v-show="!previewMarkdown"
            v-if="!restrictedToolBarItems.includes('table')"
            @insert-table="insertTable"
          />
          <!--
            The attach file button's click behavior is added by
            dropzone_input.js.
          -->
          <toolbar-button
            v-show="!previewMarkdown && !restrictedToolBarItems.includes('attach-file')"
            data-testid="button-attach-file"
            data-button-type="attach-file"
            :button-title="__('Attach a file or image')"
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
            :button-title="__('Add a quick action')"
            icon="quick-actions"
            tracking-property="quickAction"
          />
          <comment-templates-modal
            v-if="!previewMarkdown && commentTemplatePaths.length"
            :new-comment-template-paths="commentTemplatePaths"
            @select="insertSavedReply"
          />
          <template v-if="!previewMarkdown && canSummarizeChanges && !canUseComposer">
            <header-divider />
            <summarize-code-changes />
          </template>
          <slot v-if="!previewMarkdown" name="header-buttons"></slot>
        </div>
        <div v-if="!previewMarkdown" class="full-screen gl-flex gl-grow gl-justify-end">
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('full-screen')"
            class="js-zen-enter !gl-mr-0"
            icon="maximize"
            :button-title="__('Go full screen')"
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
      class="gl-border gl-absolute gl-right-0 gl-z-3 gl-flex gl-w-34 gl-rounded-bl-base gl-border-r-0 gl-bg-section gl-p-3 gl-shadow-sm"
      data-testid="find-and-replace"
    >
      <gl-form-input
        v-model="findAndReplace.find"
        :placeholder="__('Find')"
        autofocus
        data-testid="find-btn"
        @keydown="findAndReplace_handleKeyDown"
        @keyup="findAndReplace_handleKeyUp"
      />
    </div>
  </div>
</template>
