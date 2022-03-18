<script>
export default {
  props: {
    currentSlot: {
      type: String,
      required: true,
    },
    slots: {
      type: Array,
      required: true,
    },
    transitionName: {
      type: String,
      required: true,
    },
  },
  methods: {
    shouldShow(key) {
      return this.currentSlot === key;
    },
  },
};
</script>
<template>
  <div>
    <transition v-for="{ key, attributes } in slots" :key="key" :name="transitionName">
      <div v-show="shouldShow(key)" v-bind="attributes">
        <slot :name="key"></slot>
      </div>
    </transition>
  </div>
</template>
