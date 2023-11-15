<script>
import { s__ } from '~/locale';
import { MAX_FREQUENT_PROJECTS_COUNT } from '~/super_sidebar/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import currentUserFrecentProjectsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_projects.query.graphql';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedProjects',
  apollo: {
    frecentProjects: {
      query: currentUserFrecentProjectsQuery,
      skip() {
        return !this.glFeatures.frecentNamespacesSuggestions;
      },
    },
  },
  components: {
    FrequentItems,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectsPath'],
  data() {
    const username = gon.current_username;

    return {
      storageKey: username ? `${username}/frequent-projects` : null,
    };
  },
  i18n: {
    groupName: s__('Navigation|Frequently visited projects'),
    viewAllText: s__('Navigation|View all my projects'),
    emptyStateText: s__('Navigation|Projects you visit often will appear here.'),
  },
  MAX_FREQUENT_PROJECTS_COUNT,
};
</script>

<template>
  <frequent-items
    :loading="$apollo.queries.frecentProjects.loading"
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :max-items="$options.MAX_FREQUENT_PROJECTS_COUNT"
    :storage-key="storageKey"
    :items="frecentProjects"
    view-all-items-icon="project"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="projectsPath"
    v-bind="$attrs"
    v-on="$listeners"
  />
</template>
