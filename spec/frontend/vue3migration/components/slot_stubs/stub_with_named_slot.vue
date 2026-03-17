<script>
export default {
  name: 'StubWithNamedSlot',
};
</script>
<template>
  <div>
    <slot></slot>
    <div class="help-section">
      <slot name="help"></slot>
    </div>
  </div>
</template>
