<script>
import { s__ } from '~/locale';
import currentUserFrecentProjectsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_projects.query.graphql';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedProjects',
  apollo: {
    frecentProjects: {
      query: currentUserFrecentProjectsQuery,
    },
  },
  components: {
    FrequentItems,
  },
  inject: ['projectsPath'],
  i18n: {
    groupName: s__('Navigation|Frequently visited projects'),
    viewAllText: s__('Navigation|View all my projects'),
    emptyStateText: s__('Navigation|Projects you visit often will appear here.'),
  },
};
</script>

<template>
  <frequent-items
    :loading="$apollo.queries.frecentProjects.loading"
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :items="frecentProjects"
    view-all-items-icon="project"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="projectsPath"
    v-bind="$attrs"
    v-on="$listeners"
  />
</template>
