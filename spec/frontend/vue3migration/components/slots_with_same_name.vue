<script>
import Simple from './simple.vue';

export default {
  name: 'SlotsWithSameName',
  components: { Simple },
};
</script>
<template>
  <simple>
    <template v-if="true" #default>{{ $options.name }}</template>
    <template v-else #default>{{ $options.name }}</template>
  </simple>
</template>
