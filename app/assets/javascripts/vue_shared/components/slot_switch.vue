<script>
/**
 * Allows to toggle slots based on an array of slot names.
 */
export default {
  name: 'SlotSwitch',

  props: {
    activeSlotNames: {
      type: Array,
      required: true,
    },

    tagName: {
      type: String,
      required: false,
      default: 'div',
    },
  },

  computed: {
    allSlotNames() {
      return Object.keys(this.$slots);
    },
  },
};
</script>

<template>
  <component :is="tagName">
    <template v-for="slotName in allSlotNames">
      <slot v-if="activeSlotNames.includes(slotName)" :name="slotName"></slot>
    </template>
  </component>
</template>
