<script>
import { GlButton, GlPopover } from '@gitlab/ui';

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
  props: {
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>
<template>
  <span>
    <gl-button ref="popoverTrigger" variant="link" icon="question" tabindex="0" />
    <gl-popover triggers="hover focus" :target="() => $refs.popoverTrigger.$el" v-bind="options">
      <template #title>
        <!-- eslint-disable-next-line vue/no-v-html -->
        <span v-html="options.title"></span>
      </template>
      <template #default>
        <!-- eslint-disable-next-line vue/no-v-html -->
        <div v-html="options.content"></div>
      </template>
    </gl-popover>
  </span>
</template>
