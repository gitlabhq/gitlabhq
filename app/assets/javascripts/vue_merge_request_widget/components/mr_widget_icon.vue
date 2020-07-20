<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: { Icon },
  props: {
    name: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="circle-icon-container gl-mr-3 align-self-start align-self-lg-center">
    <icon :name="name" :size="24" />
  </div>
</template>
