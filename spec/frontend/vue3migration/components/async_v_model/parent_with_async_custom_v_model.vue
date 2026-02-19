<script>
export default {
  name: 'ParentWithAsyncCustomVModel',
  components: {
    AsyncInputCustom: () => import('./async_input_custom.vue'),
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
    <async-input-custom v-model="inputValue" data-testid="async-input" />
    <span data-testid="output">{{ inputValue }}</span>
  </div>
</template>
