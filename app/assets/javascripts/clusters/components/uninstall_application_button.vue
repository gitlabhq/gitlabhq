<script>
// TODO: Implement loading button component
import LoadingButton from '~/vue_shared/components/loading_button.vue';

export default {
  components: {
    LoadingButton,
  },
};
</script>

<template>
  <loading-button @click="$emit('click')" />
</template>
