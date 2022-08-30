<script>
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetChecking',
  components: {
    StateContainer,
  },
};
</script>
<template>
  <state-container status="loading">
    <span class="gl-font-weight-bold">
      {{ s__('mrWidget|Checking if merge request can be merged…') }}
    </span>
  </state-container>
</template>
