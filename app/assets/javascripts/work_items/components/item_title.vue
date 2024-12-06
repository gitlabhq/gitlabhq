<script>
import { __ } from '~/locale';

export default {
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    placeholder: {
      type: String,
      required: false,
      default: __('Add a title...'),
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    useH1: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    headerClasses() {
      return this.useH1
        ? 'gl-w-full gl-text-size-h-display !gl-m-0'
        : 'gl-font-normal sm:gl-font-bold gl-mb-1 gl-mt-0 gl-w-full';
    },
  },
  methods: {
    handleBlur({ target }) {
      this.$emit('title-changed', target.innerText);
    },
    handleInput({ target }) {
      this.$emit('title-input', target.innerText);
    },
    handleSubmit() {
      this.$refs.titleEl.blur();
    },
    handlePaste(e) {
      e.preventDefault();
      const text = e.clipboardData.getData('text');
      this.$refs.titleEl.innerText = text;
    },
  },
};
</script>

<template>
  <component
    :is="useH1 ? 'h1' : 'h2'"
    class="gl-w-full"
    :class="[{ 'gl-cursor-text': disabled }, headerClasses]"
    aria-labelledby="item-title"
  >
    <span
      id="item-title"
      ref="titleEl"
      role="textbox"
      data-testid="work-item-title"
      :aria-label="__('Title')"
      :data-placeholder="placeholder"
      :contenteditable="!disabled"
      class="hide-unfocused-input-decoration gl-border -gl-ml-4 gl-block gl-rounded-base gl-px-4 gl-py-3"
      :class="{ 'gl-pseudo-placeholder hover:gl-border-strong': !disabled }"
      @paste="handlePaste"
      @blur="handleBlur"
      @keyup="handleInput"
      @keydown.enter.exact="handleSubmit"
      @keydown.ctrl.u.prevent
      @keydown.meta.u.prevent
      @keydown.ctrl.b.prevent
      @keydown.meta.b.prevent
      >{{ title }}</span
    >
  </component>
</template>
