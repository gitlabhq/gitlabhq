<script>
import ChildWithLabelSlot from './child_with_label_slot.vue';

export default {
  name: 'ParentUsingOnlyNamedSlot',
  components: {
    ChildWithLabelSlot,
  },
};
</script>
<template>
  <child-with-label-slot>
    <template #label>
      <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
      <span data-testid="label-content">Label from named slot</span>
    </template>
  </child-with-label-slot>
</template>
