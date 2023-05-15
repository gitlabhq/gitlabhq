<script>
export default {
  name: 'VOnceInsideVIf',
};
</script>
<template>
  <div>
    <template v-if="true">
      <div v-once>{{ $options.name }}</div>
    </template>
  </div>
</template>
