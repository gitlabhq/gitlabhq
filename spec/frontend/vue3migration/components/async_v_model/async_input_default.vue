<script>
export default {
  name: 'AsyncInputDefault',
  inheritAttrs: false,
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
  methods: {
    onInput(event) {
      this.$emit('input', event.target.value);
    },
  },
};
</script>
<template>
  <input type="text" :value="value" v-bind="$attrs" @input="onInput" />
</template>
