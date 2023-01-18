<script>
import EditorModeDropdown from '~/vue_shared/components/markdown/editor_mode_dropdown.vue';
import trackUIControl from '../services/track_ui_control';
import ToolbarButton from './toolbar_button.vue';
import ToolbarImageButton from './toolbar_image_button.vue';
import ToolbarLinkButton from './toolbar_link_button.vue';
import ToolbarTableButton from './toolbar_table_button.vue';
import ToolbarTextStyleDropdown from './toolbar_text_style_dropdown.vue';
import ToolbarMoreDropdown from './toolbar_more_dropdown.vue';

export default {
  components: {
    EditorModeDropdown,
    ToolbarButton,
    ToolbarTextStyleDropdown,
    ToolbarLinkButton,
    ToolbarTableButton,
    ToolbarImageButton,
    ToolbarMoreDropdown,
  },
  methods: {
    trackToolbarControlExecution({ contentType, value }) {
      trackUIControl({ property: contentType, value });
    },
    handleEditorModeChanged(mode) {
      if (mode === 'markdown') {
        this.$emit('enableMarkdownEditor');
      }
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-wrap gl-pb-3 gl-pt-3">
    <toolbar-text-style-dropdown
      data-testid="text-styles"
      class="gl-mr-3"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="bold"
      content-type="bold"
      icon-name="bold"
      class="gl-mx-2"
      editor-command="toggleBold"
      :label="__('Bold text')"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="italic"
      content-type="italic"
      icon-name="italic"
      class="gl-mx-2"
      editor-command="toggleItalic"
      :label="__('Italic text')"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="blockquote"
      content-type="blockquote"
      icon-name="quote"
      class="gl-mx-2"
      editor-command="toggleBlockquote"
      :label="__('Insert a quote')"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="code"
      content-type="code"
      icon-name="code"
      class="gl-mx-2"
      editor-command="toggleCode"
      :label="__('Code')"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-link-button data-testid="link" @execute="trackToolbarControlExecution" />
    <toolbar-button
      data-testid="bullet-list"
      content-type="bulletList"
      icon-name="list-bulleted"
      class="gl-mx-2 gl-display-none gl-sm-display-inline"
      editor-command="toggleBulletList"
      :label="__('Add a bullet list')"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="ordered-list"
      content-type="orderedList"
      icon-name="list-numbered"
      class="gl-mx-2 gl-display-none gl-sm-display-inline"
      editor-command="toggleOrderedList"
      :label="__('Add a numbered list')"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="task-list"
      content-type="taskList"
      icon-name="list-task"
      class="gl-mx-2 gl-display-none gl-sm-display-inline"
      editor-command="toggleTaskList"
      :label="__('Add a checklist')"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-image-button
      ref="imageButton"
      data-testid="image"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-table-button data-testid="table" @execute="trackToolbarControlExecution" />
    <toolbar-more-dropdown data-testid="more" @execute="trackToolbarControlExecution" />

    <editor-mode-dropdown class="gl-ml-auto" value="richText" @input="handleEditorModeChanged" />
  </div>
</template>
<style>
.gl-spinner-container {
  text-align: left;
}
</style>
