<script>
import StubWithNamedSlot from './stub_with_named_slot.vue';

export default {
  name: 'ParentUsingStubWithNamedSlot',
  components: {
    StubWithNamedSlot,
  },
};
</script>
<template>
  <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
  <stub-with-named-slot>
    Label text
    <template #help>Help text that should not appear in label</template>
  </stub-with-named-slot>
  <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
</template>
