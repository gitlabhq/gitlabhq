<script>
import ListView from 'ee_else_ce/work_items/list/list_view.vue';

export default {
  name: 'PlanningView',
  components: {
    ListView,
  },
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
    },
    withTabs: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <list-view :root-page-full-path="rootPageFullPath" :with-tabs="withTabs" />
</template>
