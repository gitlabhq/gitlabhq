<script>
export default {
  name: 'ChildWithScopedLabelSlot',
};
</script>
<template>
  <div class="child-wrapper">
    <slot name="label" :info="'extra-info'"></slot>
    <slot></slot>
  </div>
</template>
