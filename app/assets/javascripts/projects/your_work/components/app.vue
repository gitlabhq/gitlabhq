<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { PROJECT_DASHBOARD_TABS } from '../constants';

export default {
  PROJECT_DASHBOARD_TABS,
  name: 'YourWorkProjectsApp',
  components: {
    TabsWithList,
  },
};
</script>

<template>
  <tabs-with-list :tabs="$options.PROJECT_DASHBOARD_TABS" />
</template>
