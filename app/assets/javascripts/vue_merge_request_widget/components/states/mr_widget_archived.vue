<script>
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetArchived',
  components: {
    StateContainer,
  },
};
</script>

<template>
  <state-container status="failed">
    <span class="gl-font-weight-bold">
      {{ s__('mrWidget|Merge unavailable: merge requests are read-only on archived projects.') }}
    </span>
  </state-container>
</template>
