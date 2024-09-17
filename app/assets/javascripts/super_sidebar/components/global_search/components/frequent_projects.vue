<script>
import { s__ } from '~/locale';
import currentUserFrecentProjectsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_projects.query.graphql';
import { FREQUENTLY_VISITED_PROJECTS_HANDLE } from '~/super_sidebar/components/global_search/command_palette/constants';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedProjects',
  components: {
    FrequentItems,
  },
  inject: ['projectsPath'],
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    frecentProjects: {
      query: currentUserFrecentProjectsQuery,
    },
  },
  i18n: {
    groupName: s__('Navigation|Frequently visited projects'),
    viewAllText: s__('Navigation|View all my projects'),
    emptyStateText: s__('Navigation|Projects you visit often will appear here.'),
  },
  computed: {
    items() {
      return this.frecentProjects || [];
    },
  },
  FREQUENTLY_VISITED_PROJECTS_HANDLE,
};
</script>

<template>
  <frequent-items
    :loading="$apollo.queries.frecentProjects.loading"
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :items="items"
    view-all-items-icon="project"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="projectsPath"
    v-bind="$attrs"
    v-on="$listeners"
    @action="$emit('action', $options.FREQUENTLY_VISITED_PROJECTS_HANDLE)"
  />
</template>
