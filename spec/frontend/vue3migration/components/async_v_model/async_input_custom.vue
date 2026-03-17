<script>
export default {
  name: 'AsyncInputCustom',
  inheritAttrs: false,
  model: {
    prop: 'text',
    event: 'change',
  },
  props: {
    text: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['change'],
  methods: {
    onInput(event) {
      this.$emit('change', event.target.value);
    },
  },
};
</script>
<template>
  <input type="text" :value="text" v-bind="$attrs" @input="onInput" />
</template>
