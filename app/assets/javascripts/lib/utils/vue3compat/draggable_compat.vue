<script>
import Draggable from 'vuedraggable';

export default {
  name: 'DraggableCompat',
  components: { Draggable },
  props: {
    modelValue: {
      type: Array,
      required: false,
      default: undefined,
    },
    value: {
      type: Array,
      required: false,
      default: undefined,
    },
    itemKey: {
      type: [String, Function],
      required: true,
    },
  },
  emits: ['update:modelValue', 'input', 'start', 'end'],
  computed: {
    isVue3() {
      return Boolean(this.$);
    },
    internalList() {
      if (this.isVue3 && this.modelValue !== undefined) return this.modelValue;
      return this.value;
    },
    props() {
      const props = { ...this.$attrs };
      if (this.value !== undefined) {
        props.value = this.value;
      }
      return props;
    },
  },
  methods: {
    onChange() {
      if (this.isVue3) {
        this.$emit('update:modelValue', this.internalList);
      } else {
        this.$emit('input', this.internalList);
      }
    },
    itemSlot(element) {
      if (!this.isVue3) return null;
      const children = this.$scopedSlots.default ? this.$scopedSlots.default()[0].children : [];
      if (typeof this.itemKey === 'function') {
        return children.find((child) => child.key === this.itemKey(element));
      }
      return children.find((child) => child.key === element[this.itemKey]);
    },
  },
};
</script>

<template>
  <!-- Vue 2 mode: render default slot (user v-for) -->
  <draggable v-if="!isVue3" v-bind="props" v-on="$listeners">
    <template #default>
      <slot></slot>
    </template>
  </draggable>

  <!-- Vue 3 mode: render item slot with correct props -->
  <draggable
    v-else
    v-bind="$attrs"
    :model-value="internalList"
    :item-key="itemKey"
    @change="onChange"
    @start="$emit('start', $event)"
    @end="$emit('end', $event)"
  >
    <template #item="slotProps">
      <component :is="itemSlot(slotProps.element)" v-bind="slotProps" />
    </template>
  </draggable>
</template>
