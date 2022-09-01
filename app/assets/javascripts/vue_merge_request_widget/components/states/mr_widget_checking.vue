<script>
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetChecking',
  components: {
    StateContainer,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <state-container :mr="mr" status="loading">
    <span class="gl-font-weight-bold">
      {{ s__('mrWidget|Checking if merge request can be merged…') }}
    </span>
  </state-container>
</template>
