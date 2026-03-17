<script>
export default {
  name: 'ParentWithAsyncDefaultVModel',
  components: {
    AsyncInputDefault: () => import('./async_input_default.vue'),
  },
  data() {
    return {
      inputValue: '',
    };
  },
};
</script>
<template>
  <div>
    <async-input-default v-model="inputValue" data-testid="async-input" />
    <span data-testid="output">{{ inputValue }}</span>
  </div>
</template>
