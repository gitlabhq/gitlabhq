<script>
import SimpleComponent from './simple_component.vue';

export default {
  components: {
    SimpleComponent,
  },
};
</script>
<template>
  <simple-component>
    <!-- slot comment typical for gitlab-ui, for example -->
    <!-- slot comment typical for gitlab-ui, for example -->
    <slot></slot>
    <!-- slot comment typical for gitlab-ui, for example -->
    <!-- slot comment typical for gitlab-ui, for example -->
  </simple-component>
</template>
