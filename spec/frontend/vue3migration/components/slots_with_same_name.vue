<script>
import SimpleComponent from './simple_component.vue';

export default {
  name: 'SlotsWithSameName',
  components: { SimpleComponent },
};
</script>
<template>
  <simple-component>
    <template v-if="true" #default>{{ $options.name }}</template>
    <template v-else #default>{{ $options.name }}</template>
  </simple-component>
</template>
