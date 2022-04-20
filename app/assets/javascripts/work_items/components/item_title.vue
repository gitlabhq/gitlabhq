<script>
import { escape } from 'lodash';
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
  },
  methods: {
    getSanitizedTitle(inputEl) {
      const { innerText } = inputEl;
      return escape(innerText);
    },
    handleBlur({ target }) {
      this.$emit('title-changed', this.getSanitizedTitle(target));
    },
    handleInput({ target }) {
      this.$emit('title-input', this.getSanitizedTitle(target));
    },
    handleSubmit() {
      this.$refs.titleEl.blur();
    },
  },
};
</script>

<template>
  <h2
    class="gl-font-weight-normal gl-sm-font-weight-bold gl-my-5 gl-display-inline-block"
    :class="{ 'gl-cursor-not-allowed': disabled }"
    aria-labelledby="item-title"
  >
    <span
      id="item-title"
      ref="titleEl"
      role="textbox"
      :aria-label="__('Title')"
      :data-placeholder="placeholder"
      :contenteditable="!disabled"
      class="gl-pseudo-placeholder"
      @blur="handleBlur"
      @keyup="handleInput"
      @keydown.enter.exact="handleSubmit"
      @keydown.ctrl.u.prevent
      @keydown.meta.u.prevent
      @keydown.ctrl.b.prevent
      @keydown.meta.b.prevent
      >{{ title }}</span
    >
  </h2>
</template>
