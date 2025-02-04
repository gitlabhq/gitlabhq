<script>
import CommentTemplatesModal from '~/vue_shared/components/markdown/comment_templates_modal.vue';
import { __, sprintf } from '~/locale';
import { getModifierKey } from '~/constants';
import trackUIControl from '../services/track_ui_control';
import HeaderDivider from '../../vue_shared/components/markdown/header_divider.vue';
import ToolbarButton from './toolbar_button.vue';
import ToolbarAttachmentButton from './toolbar_attachment_button.vue';
import ToolbarTableButton from './toolbar_table_button.vue';
import ToolbarTextStyleDropdown from './toolbar_text_style_dropdown.vue';
import ToolbarMoreDropdown from './toolbar_more_dropdown.vue';

export default {
  components: {
    ToolbarButton,
    ToolbarTextStyleDropdown,
    ToolbarTableButton,
    ToolbarAttachmentButton,
    ToolbarMoreDropdown,
    CommentTemplatesModal,
    HeaderDivider,
    SummarizeCodeChanges: () =>
      import('ee_component/merge_requests/components/summarize_code_changes.vue'),
  },
  inject: {
    newCommentTemplatePaths: { default: () => [] },
    tiptapEditor: { default: null },
    contentEditor: { default: null },
    canSummarizeChanges: { default: false },
  },
  props: {
    supportsQuickActions: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideAttachmentButton: {
      type: Boolean,
      default: false,
      required: false,
    },
    newCommentTemplatePathsProp: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    const modifierKey = getModifierKey();
    const shiftKey = modifierKey === '⌘' ? '⇧' : 'Shift+';

    return {
      i18n: {
        bold: sprintf(__('Bold (%{modifierKey}B)'), { modifierKey }),
        italic: sprintf(__('Italic (%{modifierKey}I)'), { modifierKey }),
        strike: sprintf(__('Strikethrough (%{modifierKey}%{shiftKey}X)'), {
          modifierKey,
          shiftKey,
        }),
        quote: __('Insert a quote'),
        code: __('Code'),
        link: sprintf(__('Insert link (%{modifierKey}K)'), { modifierKey }),
        bulletList: __('Add a bullet list'),
        numberedList: __('Add a numbered list'),
        taskList: __('Add a checklist'),
        editorToolbar: __('Editor toolbar'),
      },
    };
  },
  computed: {
    codeSuggestionsEnabled() {
      return this.contentEditor.codeSuggestionsConfig?.canSuggest;
    },
    commentTemplatePaths() {
      return this.newCommentTemplatePaths.length > 0
        ? this.newCommentTemplatePaths
        : this.newCommentTemplatePathsProp;
    },
  },
  methods: {
    trackToolbarControlExecution({ contentType, value }) {
      trackUIControl({ property: contentType, value });
    },
    insertSavedReply(savedReply) {
      this.tiptapEditor.chain().focus().pasteContent(savedReply).run();
    },
    insertTable({ rows, cols }) {
      this.tiptapEditor
        .chain()
        .focus()
        .insertTable({
          rows,
          cols,
          withHeaderRow: true,
        })
        .run();
    },
  },
};
</script>
<template>
  <div
    class="gl-border-b gl-flex gl-w-full gl-flex-wrap gl-items-center gl-gap-y-2 gl-rounded-t-base gl-border-default gl-px-3 gl-py-3"
    data-testid="formatting-toolbar"
    role="toolbar"
    :aria-label="i18n.editorToolbar"
  >
    <div class="gl-flex">
      <toolbar-text-style-dropdown
        data-testid="text-styles"
        @execute="trackToolbarControlExecution"
      />
      <header-divider />
    </div>
    <div v-if="codeSuggestionsEnabled" class="gl-flex">
      <toolbar-button
        v-if="codeSuggestionsEnabled"
        data-testid="code-suggestion"
        content-type="codeSuggestion"
        icon-name="doc-code"
        editor-command="insertCodeSuggestion"
        :label="__('Insert suggestion')"
        :show-active-state="false"
        @execute="trackToolbarControlExecution"
      />
      <header-divider />
    </div>
    <toolbar-button
      data-testid="bold"
      content-type="bold"
      icon-name="bold"
      editor-command="toggleBold"
      :label="i18n.bold"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="italic"
      content-type="italic"
      icon-name="italic"
      editor-command="toggleItalic"
      :label="i18n.italic"
      @execute="trackToolbarControlExecution"
    />
    <div class="gl-flex">
      <toolbar-button
        data-testid="strike"
        content-type="strike"
        icon-name="strikethrough"
        editor-command="toggleStrike"
        :label="i18n.strike"
        @execute="trackToolbarControlExecution"
      />
      <header-divider />
    </div>
    <toolbar-button
      data-testid="blockquote"
      content-type="blockquote"
      icon-name="quote"
      editor-command="toggleBlockquote"
      :label="i18n.quote"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="code"
      content-type="code"
      icon-name="code"
      editor-command="toggleCode"
      :label="i18n.code"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="link"
      content-type="link"
      icon-name="link"
      editor-command="editLink"
      :label="i18n.link"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="bullet-list"
      content-type="bulletList"
      icon-name="list-bulleted"
      class="gl-hidden sm:gl-inline"
      editor-command="toggleBulletList"
      :label="i18n.bulletList"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="ordered-list"
      content-type="orderedList"
      icon-name="list-numbered"
      class="gl-hidden sm:gl-inline"
      editor-command="toggleOrderedList"
      :label="i18n.numberedList"
      @execute="trackToolbarControlExecution"
    />
    <div class="gl-flex">
      <toolbar-button
        data-testid="task-list"
        content-type="taskList"
        icon-name="list-task"
        class="gl-hidden sm:gl-inline"
        editor-command="toggleTaskList"
        :label="i18n.taskList"
        @execute="trackToolbarControlExecution"
      />
      <div class="gl-hidden sm:gl-flex">
        <header-divider />
      </div>
    </div>
    <toolbar-table-button
      data-testid="table"
      @execute="trackToolbarControlExecution"
      @insert-table="insertTable"
    />
    <div class="gl-flex">
      <toolbar-attachment-button
        v-if="!hideAttachmentButton"
        data-testid="attachment"
        @execute="trackToolbarControlExecution"
      />
      <!-- TODO Add icon and trigger functionality from here -->
      <toolbar-button
        v-if="supportsQuickActions"
        data-testid="quick-actions"
        content-type="quickAction"
        icon-name="quick-actions"
        class="gl-hidden sm:gl-inline"
        editor-command="insertQuickAction"
        :label="__('Add a quick action')"
        @execute="trackToolbarControlExecution"
      />
      <header-divider v-if="commentTemplatePaths.length" />
    </div>
    <comment-templates-modal
      v-if="commentTemplatePaths.length"
      :new-comment-template-paths="commentTemplatePaths"
      @select="insertSavedReply"
    />
    <toolbar-more-dropdown data-testid="more" @execute="trackToolbarControlExecution" />
    <div v-if="canSummarizeChanges" class="gl-flex">
      <header-divider />
      <summarize-code-changes />
    </div>
    <slot name="header-buttons"></slot>
  </div>
</template>
