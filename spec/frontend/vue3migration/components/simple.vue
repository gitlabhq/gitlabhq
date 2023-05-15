<script>
export default {
  name: 'Simple',
};
</script>
<template>
  <div>
    <slot>{{ $options.name }}</slot>
  </div>
</template>
