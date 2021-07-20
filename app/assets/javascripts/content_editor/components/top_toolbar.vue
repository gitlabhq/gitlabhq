<script>
import Tracking from '~/tracking';
import { CONTENT_EDITOR_TRACKING_LABEL, TOOLBAR_CONTROL_TRACKING_ACTION } from '../constants';
import { ContentEditor } from '../services/content_editor';
import Divider from './divider.vue';
import ToolbarButton from './toolbar_button.vue';
import ToolbarImageButton from './toolbar_image_button.vue';
import ToolbarLinkButton from './toolbar_link_button.vue';
import ToolbarTableButton from './toolbar_table_button.vue';
import ToolbarTextStyleDropdown from './toolbar_text_style_dropdown.vue';

const trackingMixin = Tracking.mixin({
  label: CONTENT_EDITOR_TRACKING_LABEL,
});

export default {
  components: {
    ToolbarButton,
    ToolbarTextStyleDropdown,
    ToolbarLinkButton,
    ToolbarTableButton,
    ToolbarImageButton,
    Divider,
  },
  mixins: [trackingMixin],
  props: {
    contentEditor: {
      type: ContentEditor,
      required: true,
    },
  },
  methods: {
    trackToolbarControlExecution({ contentType: property, value }) {
      this.track(TOOLBAR_CONTROL_TRACKING_ACTION, {
        property,
        value,
      });
    },
  },
};
</script>
<template>
  <div
    class="gl-display-flex gl-justify-content-end gl-pb-3 gl-pt-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-200"
  >
    <toolbar-text-style-dropdown
      data-testid="text-styles"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <divider />
    <toolbar-button
      data-testid="bold"
      content-type="bold"
      icon-name="bold"
      editor-command="toggleBold"
      :label="__('Bold text')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="italic"
      content-type="italic"
      icon-name="italic"
      editor-command="toggleItalic"
      :label="__('Italic text')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="strike"
      content-type="strike"
      icon-name="strikethrough"
      editor-command="toggleStrike"
      :label="__('Strikethrough')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="code"
      content-type="code"
      icon-name="code"
      editor-command="toggleCode"
      :label="__('Code')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-link-button
      data-testid="link"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <divider />
    <toolbar-image-button
      ref="imageButton"
      data-testid="image"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="blockquote"
      content-type="blockquote"
      icon-name="quote"
      editor-command="toggleBlockquote"
      :label="__('Insert a quote')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="code-block"
      content-type="codeBlock"
      icon-name="doc-code"
      editor-command="toggleCodeBlock"
      :label="__('Insert a code block')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="bullet-list"
      content-type="bulletList"
      icon-name="list-bulleted"
      editor-command="toggleBulletList"
      :label="__('Add a bullet list')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="ordered-list"
      content-type="orderedList"
      icon-name="list-numbered"
      editor-command="toggleOrderedList"
      :label="__('Add a numbered list')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-button
      data-testid="horizontal-rule"
      content-type="horizontalRule"
      icon-name="dash"
      editor-command="setHorizontalRule"
      :label="__('Add a horizontal rule')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <toolbar-table-button
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
  </div>
</template>
<style>
.gl-spinner-container {
  text-align: left;
}
</style>
