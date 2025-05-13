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
  <state-container status="loading" is-collapsible>
    {{ s__('mrWidget|Checking if merge request can be merged…') }}
  </state-container>
</template>
