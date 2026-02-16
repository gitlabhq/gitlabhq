<script>
export default {
  name: 'SlotWithFallbackContent',
};
</script>
<template>
  <div>
    <slot>{{ $options.name }}</slot>
  </div>
</template>
