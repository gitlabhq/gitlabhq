<script>
import { s__ } from '~/locale';
import currentUserFrecentGroupsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_groups.query.graphql';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedGroups',
  apollo: {
    frecentGroups: {
      query: currentUserFrecentGroupsQuery,
    },
  },
  components: {
    FrequentItems,
  },
  inject: ['groupsPath'],
  i18n: {
    groupName: s__('Navigation|Frequently visited groups'),
    viewAllText: s__('Navigation|View all my groups'),
    emptyStateText: s__('Navigation|Groups you visit often will appear here.'),
  },
};
</script>

<template>
  <frequent-items
    :loading="$apollo.queries.frecentGroups.loading"
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :items="frecentGroups"
    view-all-items-icon="group"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="groupsPath"
    v-bind="$attrs"
    v-on="$listeners"
  />
</template>
