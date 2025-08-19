<script>
import NullPresenter from './null.vue';

// EE feature, for CE, delegate to null presenter
export default {
  name: 'HealthPresenter',
  components: { NullPresenter },
};
</script>
<template>
  <null-presenter />
</template>
