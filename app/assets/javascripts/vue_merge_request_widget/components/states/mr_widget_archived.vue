<script>
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetArchived',
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
  <state-container :mr="mr" status="failed">
    <span class="gl-font-weight-bold">
      {{ s__('mrWidget|Merge unavailable: merge requests are read-only on archived projects.') }}
    </span>
  </state-container>
</template>
