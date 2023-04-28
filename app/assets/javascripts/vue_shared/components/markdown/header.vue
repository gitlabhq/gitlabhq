<script>
import { GlPopover, GlButton, GlTooltipDirective, GlTabs, GlTab } from '@gitlab/ui';
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

export default {
  components: {
    ToolbarButton,
    GlPopover,
    GlButton,
    GlTabs,
    GlTab,
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
  },
  watch: {
    showSuggestPopover() {
      this.updateSuggestPopoverVisibility();
    },
  },
  mounted() {
    $(document).on('markdown-preview:show.vue', this.previewMarkdownTab);
    $(document).on('markdown-preview:hide.vue', this.writeMarkdownTab);

    this.updateSuggestPopoverVisibility();
  },
  beforeDestroy() {
    $(document).off('markdown-preview:show.vue', this.previewMarkdownTab);
    $(document).off('markdown-preview:hide.vue', this.writeMarkdownTab);
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

    previewMarkdownTab(event, form) {
      if (event.target.blur) event.target.blur();
      if (!this.isValid(form)) return;

      this.$emit('preview-markdown');
    },

    writeMarkdownTab(event, form) {
      if (event.target.blur) event.target.blur();
      if (!this.isValid(form)) return;

      this.$emit('write-markdown');
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
        const generatedByText = `${text}\n***\n_${__('This comment was generated using OpenAI')}_`;
        updateText({
          textArea,
          tag: generatedByText,
          cursorOffset: 0,
          wrap: false,
        });
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
    writeTabTitle: __('Write'),
    previewTabTitle: __('Preview'),
  },
};
</script>

<template>
  <div class="md-header">
    <gl-tabs content-class="gl-display-none">
      <gl-tab
        title-link-class="gl-py-4 gl-px-3 js-md-write-button"
        :title="$options.i18n.writeTabTitle"
        :active="!previewMarkdown"
        data-testid="write-tab"
        @click="writeMarkdownTab($event)"
      />
      <gl-tab
        v-if="enablePreview"
        title-link-class="gl-py-4 gl-px-3 js-md-preview-button"
        :title="$options.i18n.previewTabTitle"
        :active="previewMarkdown"
        data-testid="preview-tab"
        @click="previewMarkdownTab($event)"
      />

      <template #tabs-end>
        <div
          data-testid="md-header-toolbar"
          :class="{ 'gl-display-none!': previewMarkdown }"
          class="md-header-toolbar gl-ml-auto gl-py-2 gl-justify-content-center"
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
            :title="__('Attach a file or image')"
            data-testid="button-attach-file"
            category="tertiary"
            icon="paperclip"
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
          <toolbar-button
            v-if="!restrictedToolBarItems.includes('full-screen')"
            class="js-zen-enter"
            :prepend="true"
            :button-title="__('Go full screen')"
            icon="maximize"
          />
        </div>
      </template>
    </gl-tabs>
  </div>
</template>
