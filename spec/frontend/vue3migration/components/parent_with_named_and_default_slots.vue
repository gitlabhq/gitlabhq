<script>
import ChildWithSlots from './child_with_slots.vue';

export default {
  name: 'ParentWithNamedAndDefaultSlots',
  components: { ChildWithSlots },
  props: {
    showConditional: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <child-with-slots>
    <template #named>
      <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
      <span>Named slot content</span>
    </template>
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span>Default slot content</span>
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span v-if="showConditional" data-testid="conditional">Conditional content</span>
  </child-with-slots>
</template>
