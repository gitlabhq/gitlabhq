<script>
import { __ } from '~/locale';
import { DISPLAY_QUERY_GROUPS, DISPLAY_QUERY_PROJECTS } from '../constants';
import GroupsPage from './groups_page.vue';
import ProjectsPage from './projects_page.vue';

export default {
  i18n: {
    pageTitle: __('Groups and projects'),
  },
  computed: {
    routerView() {
      const { display } = this.$route.query;

      switch (display) {
        case DISPLAY_QUERY_GROUPS:
          return GroupsPage;

        case DISPLAY_QUERY_PROJECTS:
          return ProjectsPage;

        default:
          return GroupsPage;
      }
    },
  },
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h-display">{{ $options.i18n.pageTitle }}</h1>
    <component :is="routerView" />
  </div>
</template>
