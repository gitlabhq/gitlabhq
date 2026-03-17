<script>
export default {
  name: 'ChildRenderingAllSlots',
};
</script>
<template>
  <div>
    <!-- eslint-disable-next-line vue/no-v-for-template-key -->
    <template v-for="(_, name) in $scopedSlots">
      <div :key="name" :data-testid="'slot-' + name">
        <!-- eslint-disable-next-line vue/html-self-closing -->
        <slot :name="name"></slot>
      </div>
    </template>
  </div>
</template>
