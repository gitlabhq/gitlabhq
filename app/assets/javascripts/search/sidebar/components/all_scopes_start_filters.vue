<script>
import GroupFilter from './group_filter.vue';
import ProjectFilter from './project_filter.vue';

export default {
  name: 'AllScopesStartFilters',
  components: {
    GroupFilter,
    ProjectFilter,
  },
};
</script>

<template>
  <div class="gl-p-4 gl-pb-0">
    <group-filter class="gl-mb-5" />
    <project-filter class="gl-mb-5" />
  </div>
</template>
