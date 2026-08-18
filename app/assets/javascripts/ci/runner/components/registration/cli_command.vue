<script>
import { s__ } from '~/locale';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';

export default {
  name: 'CliCommand',
  components: {
    CodeBlockHighlighted,
    SimpleCopyButton,
  },
  props: {
    prompt: {
      type: String,
      required: false,
      default: '',
    },
    command: {
      type: [Array, String],
      required: false,
      default: '',
    },
    buttonTitle: {
      type: String,
      required: false,
      default: s__('Runners|Copy command'),
    },
    language: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    lines() {
      if (typeof this.command === 'string') {
        return [this.command];
      }
      return this.command;
    },
    clipboard() {
      return this.lines?.join('') || '';
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-items-start gl-gap-3">
    <code-block-highlighted
      v-if="language"
      class="gl-border gl-w-full gl-p-4"
      max-height="300px"
      :language="language"
      :code="clipboard"
    />
    <!-- eslint-disable vue/require-v-for-key-->
    <pre
      v-else
      class="gl-w-full"
      :style="{ maxHeight: '300px' }"
    ><span v-if="prompt" class="gl-select-none">{{ prompt }} </span><template v-for="line in lines">{{ line }}<br class="gl-select-none" /></template></pre>
    <!-- eslint-enable vue/require-v-for-key-->

    <simple-copy-button :text="clipboard" :title="buttonTitle" />
  </div>
</template>
