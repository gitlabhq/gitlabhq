<script>
import Vue from 'vue';

const ITEM_VALUE = 'group-1';

// eslint-disable-next-line vue/one-component-per-file
const ListboxItem = Vue.extend({
  name: 'ListboxItem',
  props: {},
  render(h) {
    return h(
      'button',
      {
        on: {
          click: () => {
            // eslint-disable-next-line vue/require-explicit-emits -- intentional for repro
            this.$emit('select', true);
          },
        },
      },
      'Select',
    );
  },
});

// eslint-disable-next-line vue/one-component-per-file
const Listbox = Vue.extend({
  name: 'ListboxItem',
  components: {
    ListboxItem,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      item: { value: ITEM_VALUE },
    };
  },
  methods: {
    onSelect(item) {
      // eslint-disable-next-line vue/require-explicit-emits -- intentional for repro
      this.$emit('select', item.value);
    },
  },
  template: '<ListboxItem ref="item" :item="item" @select="onSelect(item, $event)" />',
  render(h) {
    return h(ListboxItem, {
      ref: 'item',
      on: {
        select: ($event) => {
          this.onSelect(this.item, $event);
        },
      },
    });
  },
});

// eslint-disable-next-line vue/one-component-per-file
export default {
  name: 'ShadowingDemo',
  components: {
    Listbox,
  },
  data() {
    return {
      label: 'initial',
      selected: null,
    };
  },
  methods: {
    handleSelect(payload) {
      this.selected = payload;
    },
  },
};
</script>
<template><listbox ref="listbox" :label="label" @select="handleSelect" /></template>
