<script>
import Draggable from 'vuedraggable';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

// A `v-for` in the slot compiles to one fragment vnode holding everything it produced,
// so swap each fragment for its children to get the flat list the consumer wrote. Only
// fragments have a symbol type and array children; text and comment vnodes hold a string.
const flattenSlotNodes = (nodes) =>
  nodes.flatMap((node) =>
    typeof node?.type === 'symbol' && Array.isArray(node.children)
      ? flattenSlotNodes(node.children)
      : [node],
  );

export default {
  name: 'DraggableCompat',
  components: { Draggable },
  mixins: [glSlotsMixin, glListenersMixin],
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
  compatConfig: {
    MODE: 3,
    COMPONENT_V_MODEL: false,
  },
  emits: ['update:modelValue', 'input', 'start', 'end', 'update', 'change'],
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
    itemSlot(element) {
      if (!this.isVue3) return null;

      const targetKey =
        typeof this.itemKey === 'function' ? this.itemKey(element) : element[this.itemKey];

      return flattenSlotNodes(this.glSlots().default?.() ?? []).find(
        (node) => node?.key === targetKey,
      );
    },
    emitInputEvents(event) {
      this.$emit('update:modelValue', event);
      this.$emit('input', event);
    },
  },
};
</script>

<template>
  <!-- Vue 2 mode: render default slot (user v-for) -->
  <draggable v-if="!isVue3" v-bind="props" v-on="glListeners()">
    <template v-if="glSlots().header" #header>
      <slot name="header"></slot>
    </template>
    <template v-if="glSlots().default" #default>
      <slot></slot>
    </template>
    <template v-if="glSlots().footer" #footer>
      <slot name="footer"></slot>
    </template>
  </draggable>

  <!-- Vue 3 mode: render item slot with correct props -->
  <draggable
    v-else
    v-bind="$attrs"
    :model-value="internalList"
    :item-key="itemKey"
    @change="$emit('change', $event)"
    @start="$emit('start', $event)"
    @end="$emit('end', $event)"
    @update="$emit('update', $event)"
    @update:model-value="emitInputEvents"
  >
    <template v-if="glSlots().header" #header>
      <slot name="header"></slot>
    </template>
    <template #item="slotProps">
      <component :is="itemSlot(slotProps.element)" v-bind="slotProps" />
    </template>
    <template v-if="glSlots().footer" #footer>
      <slot name="footer"></slot>
    </template>
  </draggable>
</template>
