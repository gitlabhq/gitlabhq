<script>
import Divider from './divider.vue';
import ToolbarButton from './toolbar_button.vue';

export default {
  components: {
    ToolbarButton,
    Divider,
  },
  props: {
    editor: {
      type: Object,
      required: true,
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
      :label="__('Bold text')"
      :editor="editor"
    />
    <toolbar-button
      data-testid="italic"
      content-type="italic"
      icon-name="italic"
      :label="__('Italic text')"
      :editor="editor"
    />
    <toolbar-button
      data-testid="code"
      content-type="code"
      icon-name="code"
      :label="__('Code')"
      :editor="editor"
    />
    <divider />
    <toolbar-button
      data-testid="blockquote"
      content-type="blockquote"
      icon-name="quote"
      :label="__('Insert a quote')"
      :editor="editor"
    />
    <toolbar-button
      data-testid="bullet-list"
      content-type="bullet_list"
      icon-name="list-bulleted"
      :label="__('Add a bullet list')"
      :editor="editor"
    />
    <toolbar-button
      data-testid="ordered-list"
      content-type="ordered_list"
      icon-name="list-numbered"
      :label="__('Add a numbered list')"
      :editor="editor"
    />
  </div>
</template>
