<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    buttonTitle: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
    tag: {
      type: String,
      required: true,
    },
    tagBlock: {
      type: String,
      required: false,
      default: '',
    },
    tagSelect: {
      type: String,
      required: false,
      default: '',
    },
    prepend: {
      type: Boolean,
      required: false,
      default: false,
    },
    tagContent: {
      type: String,
      required: false,
      default: '',
    },
    cursorOffset: {
      type: Number,
      required: false,
      default: 0,
    },

    /**
     * A string (or an array of strings) of
     * [mousetrap](https://craig.is/killing/mice) keyboard shortcuts
     * that should be attached to this button. For example:
     * "command+k"
     * ...or...
     * ["command+k", "ctrl+k"]
     */
    shortcuts: {
      type: [String, Array],
      required: false,
      default: () => [],
    },
  },
  computed: {
    shortcutsString() {
      const shortcutArray = Array.isArray(this.shortcuts) ? this.shortcuts : [this.shortcuts];
      return JSON.stringify(shortcutArray);
    },
  },
};
</script>

<template>
  <button
    v-gl-tooltip
    :data-md-tag="tag"
    :data-md-cursor-offset="cursorOffset"
    :data-md-select="tagSelect"
    :data-md-block="tagBlock"
    :data-md-tag-content="tagContent"
    :data-md-prepend="prepend"
    :data-md-shortcuts="shortcutsString"
    :title="buttonTitle"
    :aria-label="buttonTitle"
    type="button"
    class="toolbar-btn js-md"
    data-container="body"
    @click="() => $emit('click')"
  >
    <gl-icon :name="icon" />
  </button>
</template>
