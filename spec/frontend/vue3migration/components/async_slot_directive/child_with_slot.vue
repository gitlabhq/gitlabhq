<script>
export default {
  name: 'ChildWithSlot',
};
</script>

<template>
  <div data-testid="child-wrapper">
    <slot name="content"></slot>
  </div>
</template>
