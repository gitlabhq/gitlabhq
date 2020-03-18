<script>
import VirtualList from 'vue-virtual-scroll-list';

export default {
  name: 'SmartVirtualList',
  components: { VirtualList },
  props: {
    size: { type: Number, required: true },
    length: { type: Number, required: true },
    remain: { type: Number, required: true },
    rtag: { type: String, default: 'div', required: false },
    wtag: { type: String, default: 'div', required: false },
    wclass: { type: String, default: null, required: false },
  },
};
</script>
<template>
  <virtual-list
    v-if="length > remain"
    v-bind="$attrs"
    :size="remain"
    :remain="remain"
    :rtag="rtag"
    :wtag="wtag"
    :wclass="wclass"
    class="js-virtual-list"
  >
    <slot></slot>
  </virtual-list>
  <component :is="rtag" v-else class="js-plain-element">
    <component :is="wtag" :class="wclass"> <slot></slot> </component>
  </component>
</template>
