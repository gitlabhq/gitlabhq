<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { TOOLBAR_CONTROL_TRACKING_ACTION, MARKDOWN_EDITOR_TRACKING_LABEL } from './tracking';

export default {
  components: {
    GlButton,
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
      required: false,
      default: '',
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
    command: {
      type: String,
      required: false,
      default: '',
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
    trackingProperty: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    shortcutsString() {
      const shortcutArray = Array.isArray(this.shortcuts) ? this.shortcuts : [this.shortcuts];
      return JSON.stringify(shortcutArray);
    },
    trackingProps() {
      const { trackingProperty } = this;

      return trackingProperty
        ? {
            'data-track-action': TOOLBAR_CONTROL_TRACKING_ACTION,
            'data-track-label': MARKDOWN_EDITOR_TRACKING_LABEL,
            'data-track-property': trackingProperty,
          }
        : {};
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    :data-md-tag="tag"
    :data-md-cursor-offset="cursorOffset"
    :data-md-select="tagSelect"
    :data-md-block="tagBlock"
    :data-md-tag-content="tagContent"
    :data-md-prepend="prepend"
    :data-md-shortcuts="shortcutsString"
    :data-md-command="command"
    :title="buttonTitle"
    :aria-label="buttonTitle"
    :icon="icon"
    v-bind="trackingProps"
    type="button"
    category="tertiary"
    size="small"
    class="js-md gl-mr-2"
    data-container="body"
    @click="$emit('click', $event)"
  />
</template>
