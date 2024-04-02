<script>
import { GlButton, GlPopover } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';

/**
 * Render a button with a question mark icon
 * On hover shows a popover. The popover will be dismissed on mouseleave
 */
export default {
  name: 'HelpPopover',
  components: {
    GlButton,
    GlPopover,
  },
  directives: {
    SafeHtml,
  },
  props: {
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    icon: {
      type: String,
      required: false,
      default: 'question-o',
    },
    triggerClass: {
      type: [String, Array, Object],
      required: false,
      default: '',
    },
    ariaLabel: {
      type: String,
      required: false,
      default: __('Help'),
    },
  },
  methods: {
    targetFn() {
      return this.$refs.popoverTrigger?.$el;
    },
  },
};
</script>
<template>
  <span>
    <gl-button
      ref="popoverTrigger"
      :class="triggerClass"
      variant="link"
      :icon="icon"
      :aria-label="ariaLabel"
    />
    <gl-popover :target="targetFn" v-bind="options">
      <template v-if="options.title" #title>
        <span v-safe-html="options.title"></span>
      </template>
      <template #default>
        <div v-safe-html="options.content"></div>
      </template>
      <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
      <template v-for="slot in Object.keys($slots)" #[slot]>
        <slot :name="slot"></slot>
      </template>
    </gl-popover>
  </span>
</template>
