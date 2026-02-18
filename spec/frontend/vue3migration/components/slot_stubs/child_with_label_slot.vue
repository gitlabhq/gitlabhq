<script>
export default {
  name: 'ChildWithLabelSlot',
};
</script>
<template>
  <div>
    <div class="label-section">
      <slot name="label"></slot>
    </div>
    <div class="content-section">
      <slot></slot>
    </div>
  </div>
</template>
