<script>
import { s__ } from '~/locale';
import { MAX_FREQUENT_PROJECTS_COUNT } from '~/super_sidebar/constants';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedProjects',
  components: {
    FrequentItems,
  },
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
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :max-items="$options.MAX_FREQUENT_PROJECTS_COUNT"
    :storage-key="storageKey"
    view-all-items-icon="project"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="projectsPath"
    v-bind="$attrs"
    v-on="$listeners"
  />
</template>
