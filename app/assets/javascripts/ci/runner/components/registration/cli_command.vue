<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  components: {
    ClipboardButton,
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
  },
  computed: {
    lines() {
      if (typeof this.command === 'string') {
        return [this.command];
      }
      return this.command;
    },
    clipboard() {
      return this.lines.join('');
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-gap-3 gl-align-items-flex-start">
    <!-- eslint-disable vue/require-v-for-key-->
    <pre
      class="gl-w-full"
    ><span v-if="prompt" class="gl-user-select-none">{{ prompt }} </span><template v-for="line in lines">{{ line }}<br class="gl-user-select-none"/></template></pre>
    <!-- eslint-enable vue/require-v-for-key-->
    <clipboard-button :text="clipboard" :title="__('Copy')" />
  </div>
</template>
