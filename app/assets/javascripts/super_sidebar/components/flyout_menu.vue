<script>
import { computePosition, autoUpdate, offset, flip, shift } from '@floating-ui/dom';
import NavItem from './nav_item.vue';

export default {
  name: 'FlyoutMenu',
  components: { NavItem },
  props: {
    targetId: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
  },
  cleanupFunction: undefined,
  mounted() {
    const target = document.querySelector(`#${this.targetId}`);
    const flyout = document.querySelector(`#${this.targetId}-flyout`);

    function updatePosition() {
      return computePosition(target, flyout, {
        middleware: [offset({ alignmentAxis: -12 }), flip(), shift()],
        placement: 'right-start',
        strategy: 'fixed',
      }).then(({ x, y }) => {
        Object.assign(flyout.style, {
          left: `${x}px`,
          top: `${y}px`,
        });
      });
    }

    this.$options.cleanupFunction = autoUpdate(target, flyout, updatePosition);
  },
  beforeUnmount() {
    this.$options.cleanupFunction();
  },
};
</script>

<template>
  <div
    :id="`${targetId}-flyout`"
    class="gl-fixed gl-p-4 gl-mx-n1 gl-z-index-9999 gl-max-h-full gl-overflow-y-auto"
    @mouseover="$emit('mouseover')"
    @mouseleave="$emit('mouseleave')"
  >
    <ul
      v-if="items.length > 0"
      class="gl-min-w-20 gl-max-w-34 gl-border-1 gl-rounded-base gl-border-solid gl-border-gray-100 gl-shadow-md gl-bg-white gl-p-2 gl-pb-1 gl-list-style-none"
    >
      <nav-item
        v-for="item of items"
        :key="item.id"
        :item="item"
        :is-flyout="true"
        @pin-add="(itemId) => $emit('pin-add', itemId)"
        @pin-remove="(itemId) => $emit('pin-remove', itemId)"
      />
    </ul>
  </div>
</template>
