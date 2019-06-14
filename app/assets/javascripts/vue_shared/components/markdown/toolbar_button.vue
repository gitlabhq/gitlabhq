<script>
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '../icon.vue';

export default {
  components: {
    Icon,
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
    :title="buttonTitle"
    :aria-label="buttonTitle"
    type="button"
    class="toolbar-btn js-md"
    tabindex="-1"
    data-container="body"
    @click="() => $emit('click')"
  >
    <icon :name="icon" />
  </button>
</template>
