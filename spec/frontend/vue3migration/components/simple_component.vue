<script>
export default {
  name: 'SimpleComponent',
};
</script>
<template>
  <div>
    <slot>{{ $options.name }}</slot>
  </div>
</template>
