<script>
import Simple from './simple.vue';

export default {
  components: {
    Simple,
  },
};
</script>
<template>
  <simple>
    <template #default>
      <!-- slot comment typical for gitlab-ui, for example -->
      <!-- slot comment typical for gitlab-ui, for example -->
      <slot></slot>
      <!-- slot comment typical for gitlab-ui, for example -->
      <!-- slot comment typical for gitlab-ui, for example -->
    </template>
  </simple>
</template>
