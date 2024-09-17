<script>
import { s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  components: {
    ModalCopyButton,
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
    modalId: {
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
    <!-- eslint-disable vue/require-v-for-key-->
    <pre
      class="gl-w-full"
      :style="{ maxHeight: '300px' }"
    ><span v-if="prompt" class="gl-select-none">{{ prompt }} </span><template v-for="line in lines">{{ line }}<br class="gl-select-none" /></template></pre>
    <!-- eslint-enable vue/require-v-for-key-->

    <modal-copy-button :text="clipboard" :modal-id="modalId" :title="buttonTitle" />
  </div>
</template>
