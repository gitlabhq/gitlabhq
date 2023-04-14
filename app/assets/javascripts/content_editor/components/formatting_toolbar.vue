<script>
import trackUIControl from '../services/track_ui_control';
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
  },
  methods: {
    trackToolbarControlExecution({ contentType, value }) {
      trackUIControl({ property: contentType, value });
    },
  },
};
</script>
<template>
  <div
    class="gl-w-full gl-border-b gl-display-flex gl-justify-content-end"
    data-testid="formatting-toolbar"
  >
    <div class="gl-py-2 gl-display-flex gl-flex-wrap gl-align-items-end">
      <toolbar-text-style-dropdown
        data-testid="text-styles"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="bold"
        content-type="bold"
        icon-name="bold"
        editor-command="toggleBold"
        :label="__('Bold text')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="italic"
        content-type="italic"
        icon-name="italic"
        editor-command="toggleItalic"
        :label="__('Italic text')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="blockquote"
        content-type="blockquote"
        icon-name="quote"
        editor-command="toggleBlockquote"
        :label="__('Insert a quote')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="code"
        content-type="code"
        icon-name="code"
        editor-command="toggleCode"
        :label="__('Code')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="link"
        content-type="link"
        icon-name="link"
        editor-command="editLink"
        :label="__('Insert link')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="bullet-list"
        content-type="bulletList"
        icon-name="list-bulleted"
        class="gl-display-none gl-sm-display-inline"
        editor-command="toggleBulletList"
        :label="__('Add a bullet list')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="ordered-list"
        content-type="orderedList"
        icon-name="list-numbered"
        class="gl-display-none gl-sm-display-inline"
        editor-command="toggleOrderedList"
        :label="__('Add a numbered list')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-button
        data-testid="task-list"
        content-type="taskList"
        icon-name="list-task"
        class="gl-display-none gl-sm-display-inline"
        editor-command="toggleTaskList"
        :label="__('Add a checklist')"
        @execute="trackToolbarControlExecution"
      />
      <toolbar-table-button data-testid="table" @execute="trackToolbarControlExecution" />
      <toolbar-attachment-button data-testid="attachment" @execute="trackToolbarControlExecution" />
      <toolbar-more-dropdown data-testid="more" @execute="trackToolbarControlExecution" />
    </div>
  </div>
</template>
<style>
.gl-spinner-container {
  text-align: left;
}
</style>
