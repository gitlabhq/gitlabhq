<script>
import ChildRenderingAllSlots from './child_rendering_all_slots.vue';

export default {
  name: 'ParentWithSlotOrder',
  components: { ChildRenderingAllSlots },
};
</script>
<template>
  <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
  <child-rendering-all-slots>
    <template #first>First slot</template>
    Default content
    <template #last>Last slot</template>
  </child-rendering-all-slots>
  <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
</template>
