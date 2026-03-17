<script>
import ChildWithMultipleSlots from './child_with_multiple_slots.vue';

export default {
  name: 'ParentWithSlotOrderForStub',
  components: { ChildWithMultipleSlots },
};
</script>
<template>
  <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
  <child-with-multiple-slots>
    <template #header>Header content</template>
    Body content
    <template #footer>Footer content</template>
  </child-with-multiple-slots>
  <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
</template>
