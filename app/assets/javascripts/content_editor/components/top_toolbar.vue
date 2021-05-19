<script>
import Tracking from '~/tracking';
import { CONTENT_EDITOR_TRACKING_LABEL, TOOLBAR_CONTROL_TRACKING_ACTION } from '../constants';
import { ContentEditor } from '../services/content_editor';
import Divider from './divider.vue';
import ToolbarButton from './toolbar_button.vue';

const trackingMixin = Tracking.mixin({
  label: CONTENT_EDITOR_TRACKING_LABEL,
});

export default {
  components: {
    ToolbarButton,
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
      data-testid="code"
      content-type="code"
      icon-name="code"
      editor-command="toggleCode"
      :label="__('Code')"
      :tiptap-editor="contentEditor.tiptapEditor"
      @execute="trackToolbarControlExecution"
    />
    <divider />
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
  </div>
</template>
