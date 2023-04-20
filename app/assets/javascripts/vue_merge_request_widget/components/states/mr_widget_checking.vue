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
  <state-container
    status="loading"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    {{ s__('mrWidget|Checking if merge request can be merged…') }}
  </state-container>
</template>
