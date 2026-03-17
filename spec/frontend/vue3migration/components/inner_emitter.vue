<script>
export default {
  name: 'InnerEmitter',
  emits: ['shown'],
};
</script>

<template>
  <div>
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <button data-testid="emit-btn" @click="$emit('shown')">Emit shown</button>
  </div>
</template>
