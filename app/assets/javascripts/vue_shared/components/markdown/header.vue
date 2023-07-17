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

export default {
  components: {
    ToolbarButton,
    GlPopover,
    GlButton,
    DrawioToolbarButton,
    CommentTemplatesDropdown,
    AiActionsDropdown: () => import('ee_component/ai/components/ai_actions_dropdown.vue'),
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
      const textArea = this.$el.closest('.md-area')?.querySelector('textarea');
      const addendum = headSha
        ? sprintf(descriptionForSha, { revision: truncateSha(headSha) })
        : description;

      if (textArea) {
        textArea.value = '';
        updateText({
          textArea,
          tag: `${text}\n\n---\n\n_${addendum}_`,
          cursorOffset: 0,
          wrap: false,
        });
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
  <div class="md-header gl-border-b gl-border-gray-100 gl-px-3">
    <div class="gl-display-flex gl-align-items-center gl-flex-wrap">
      <div
        data-testid="md-header-toolbar"
        class="md-header-toolbar gl-display-flex gl-py-3 gl-flex-wrap gl-row-gap-3"
      >
        <gl-button
          v-if="enablePreview"
          data-testid="preview-toggle"
          value="preview"
          :label="$options.i18n.previewTabTitle"
          class="js-md-preview-button gl-flex-direction-row-reverse gl-align-items-center gl-font-weight-normal! gl-mr-2"
          size="small"
          category="tertiary"
          @click="switchPreview"
          >{{ previewMarkdown ? $options.i18n.hidePreview : $options.i18n.preview }}</gl-button
        >
        <template v-if="!previewMarkdown && canSuggest">
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
              data-qa-selector="dismiss_suggestion_popover_button"
              @click="handleSuggestDismissed"
            >
              {{ __('Got it') }}
            </gl-button>
          </gl-popover>
        </template>
        <ai-actions-dropdown
          v-if="!previewMarkdown && editorAiActions.length"
          :actions="editorAiActions"
          @input="insertAIAction"
          @replace="replaceTextarea"
        />
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
        />
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
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('quote')"
          v-show="!previewMarkdown"
          :prepend="true"
          :tag="tag"
          :button-title="__('Insert a quote')"
          icon="quote"
          @click="handleQuote"
        />
        <toolbar-button
          v-show="!previewMarkdown"
          tag="`"
          tag-block="```"
          :button-title="__('Insert code')"
          icon="code"
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
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('bullet-list')"
          v-show="!previewMarkdown"
          :prepend="true"
          tag="- "
          :button-title="__('Add a bullet list')"
          icon="list-bulleted"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('numbered-list')"
          v-show="!previewMarkdown"
          :prepend="true"
          tag="1. "
          :button-title="__('Add a numbered list')"
          icon="list-numbered"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('task-list')"
          v-show="!previewMarkdown"
          :prepend="true"
          tag="- [ ] "
          :button-title="__('Add a checklist')"
          icon="list-task"
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
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('collapsible-section')"
          v-show="!previewMarkdown"
          :tag="mdCollapsibleSection"
          :prepend="true"
          tag-select="Click to expand"
          :button-title="__('Add a collapsible section')"
          icon="details-block"
        />
        <toolbar-button
          v-if="!restrictedToolBarItems.includes('table')"
          v-show="!previewMarkdown"
          :tag="mdTable"
          :prepend="true"
          :button-title="__('Add a table')"
          icon="table"
        />
        <gl-button
          v-if="!previewMarkdown && !restrictedToolBarItems.includes('attach-file')"
          v-gl-tooltip
          :aria-label="__('Attach a file or image')"
          :title="__('Attach a file or image')"
          class="gl-mr-3"
          data-testid="button-attach-file"
          category="tertiary"
          icon="paperclip"
          size="small"
          @click="handleAttachFile"
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
        />
        <comment-templates-dropdown
          v-if="!previewMarkdown && newCommentTemplatePath && glFeatures.savedReplies"
          :new-comment-template-path="newCommentTemplatePath"
          @select="insertSavedReply"
        />
        <div v-if="!previewMarkdown" class="full-screen">
          <gl-button
            v-if="!restrictedToolBarItems.includes('full-screen')"
            v-gl-tooltip
            class="js-zen-enter"
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
  </div>
</template>
