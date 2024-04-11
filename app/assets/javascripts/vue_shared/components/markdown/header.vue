<!-- eslint-disable vue/multi-word-component-names -->
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
import { truncateSha } from '~/lib/utils/text_utility';
import { s__, __, sprintf } from '~/locale';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { updateText } from '~/lib/utils/text_markdown';
import ToolbarButton from './toolbar_button.vue';
import DrawioToolbarButton from './drawio_toolbar_button.vue';
import CommentTemplatesDropdown from './comment_templates_dropdown.vue';
import HeaderDivider from './header_divider.vue';

export default {
  components: {
    ToolbarButton,
    GlPopover,
    GlButton,
    DrawioToolbarButton,
    CommentTemplatesDropdown,
    AiActionsDropdown: () => import('ee_component/ai/components/ai_actions_dropdown.vue'),
    HeaderDivider,
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
      modifierKey,
      shiftKey: modifierKey === '⌘' ? '⇧' : 'Shift+',
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
    hideDividerBeforeTable() {
      return (
        this.previewMarkdown ||
        (this.restrictedToolBarItems.includes('table') &&
          this.restrictedToolBarItems.includes('attach-file') &&
          !this.drawioEnabled &&
          !this.supportsQuickActions &&
          !this.newCommentTemplatePath)
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
    insertIntoTextarea(text) {
      const textArea = this.$el.closest('.md-area')?.querySelector('textarea');
      if (textArea) {
        updateText({
          textArea,
          tag: text,
          cursorOffset: 0,
          wrap: false,
        });
      }
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
    comment: __('This comment was generated by AI'),
    description: s__('MergeRequest|This description was generated using AI'),
    descriptionForSha: s__(
      'MergeRequest|This description was generated for revision %{revision} using AI',
    ),
    hidePreview: __('Continue editing'),
    preview: __('Preview'),
  },
};
</script>

<template>
  <div
    class="md-header gl-bg-white gl-border-b gl-border-gray-100 gl-rounded-lg gl-rounded-bottom-left-none gl-rounded-bottom-right-none gl-px-3"
    :class="{ 'md-header-preview': previewMarkdown }"
  >
    <div class="gl-display-flex gl-align-items-center gl-flex-wrap">
      <div
        data-testid="md-header-toolbar"
        class="md-header-toolbar gl-display-flex gl-py-3 gl-row-gap-2 gl-flex-grow-1 gl-align-items-flex-start"
      >
        <div class="gl-display-flex gl-flex-wrap gl-row-gap-2">
          <gl-button
            v-if="enablePreview"
            data-testid="preview-toggle"
            :value="previewMarkdown ? 'preview' : 'edit'"
            :label="$options.i18n.previewTabTitle"
            class="js-md-preview-button gl-flex-direction-row-reverse gl-align-items-center gl-font-weight-normal!"
            size="small"
            category="tertiary"
            @click="switchPreview"
            >{{ previewMarkdown ? $options.i18n.hidePreview : $options.i18n.preview }}</gl-button
          >
          <template v-if="!previewMarkdown && canSuggest">
            <div class="gl-display-flex gl-row-gap-2">
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
          <div class="gl-display-flex gl-row-gap-2">
            <div
              v-if="!previewMarkdown && editorAiActions.length"
              class="gl-display-flex gl-row-gap-2"
            >
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
          <div class="gl-display-flex gl-row-gap-2">
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
            tracking-property="indent"
          />
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('outdent')"
            v-show="!previewMarkdown"
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
            tracking-property="outdent"
          />
          <div class="gl-display-flex gl-row-gap-2">
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
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('table')"
            v-show="!previewMarkdown"
            :tag="mdTable"
            :prepend="true"
            :button-title="__('Add a table')"
            icon="table"
            tracking-property="table"
          />
          <!--
            The attach file button's click behavior is added by
            dropzone_input.js.
          -->
          <toolbar-button
            v-if="!previewMarkdown && !restrictedToolBarItems.includes('attach-file')"
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
          <comment-templates-dropdown
            v-if="!previewMarkdown && newCommentTemplatePaths.length"
            :new-comment-template-paths="newCommentTemplatePaths"
            @select="insertSavedReply"
          />
        </div>
        <div
          v-if="!previewMarkdown"
          class="full-screen gl-flex-grow-1 gl-justify-content-end gl-display-flex"
        >
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('full-screen')"
            class="js-zen-enter gl-mr-0!"
            icon="maximize"
            :button-title="__('Go full screen')"
            :prepend="true"
            tracking-property="fullScreen"
          />
        </div>
      </div>
    </div>
  </div>
</template>
