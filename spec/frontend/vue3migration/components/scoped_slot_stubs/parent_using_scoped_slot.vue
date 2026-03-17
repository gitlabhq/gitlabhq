<script>
import ChildWithScopedLabelSlot from './child_with_scoped_label_slot.vue';

export default {
  name: 'ParentUsingScopedSlot',
  components: {
    ChildWithScopedLabelSlot,
  },
};
</script>
<template>
  <child-with-scoped-label-slot>
    <template #label="{ info }">
      <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
      <span data-testid="label-content">Label with {{ info }}</span>
    </template>
  </child-with-scoped-label-slot>
</template>
