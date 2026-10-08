<script>
import { GlTooltip } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { s__, sprintf } from '~/locale';

export default {
  name: 'PlaceholderWrapper',
  components: { NodeViewWrapper, GlTooltip },
  props: {
    node: { type: Object, required: true },
    selected: { type: Boolean, required: false, default: false },
  },
  computed: {
    text() {
      return this.node.attrs.value || this.node.attrs.placeholder;
    },
    tooltip() {
      return this.node.attrs.value ? this.node.attrs.placeholder : null;
    },
    announcement() {
      if (!this.selected) return '';

      const { placeholder, value } = this.node.attrs;

      return value
        ? sprintf(
            s__('ContentEditor|%{value}, placeholder %{placeholder}'),
            { value, placeholder },
            false,
          )
        : sprintf(s__('ContentEditor|Placeholder %{placeholder}'), { placeholder }, false);
    },
  },
};
</script>
<template>
  <node-view-wrapper
    as="span"
    data-testid="content-editor-placeholder"
    class="content-editor-placeholder"
    :class="{ 'content-editor-placeholder-selected': selected }"
    >{{ text
    }}<gl-tooltip
      v-if="tooltip"
      :target="() => $el"
      :show="selected"
      placement="top"
      boundary="viewport"
      triggers="hover"
      >{{ tooltip }}</gl-tooltip
    ><span
      class="gl-sr-only"
      aria-live="polite"
      data-testid="content-editor-placeholder-announcement"
      >{{ announcement }}</span
    ></node-view-wrapper
  >
</template>
