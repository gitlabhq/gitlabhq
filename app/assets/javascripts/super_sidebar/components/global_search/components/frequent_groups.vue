<script>
import { s__ } from '~/locale';
import currentUserFrecentGroupsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_groups.query.graphql';
import { FREQUENTLY_VISITED_GROUPS_HANDLE } from '~/super_sidebar/components/global_search/command_palette/constants';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedGroups',
  components: {
    FrequentItems,
  },
  inject: ['groupsPath'],
  emits: ['action', 'nothing-to-render'],
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    frecentGroups: {
      query: currentUserFrecentGroupsQuery,
      skip() {
        return !this.isLoggedIn;
      },
    },
  },
  i18n: {
    groupName: s__('Navigation|Frequently visited groups'),
    viewAllText: s__('Navigation|View all my groups'),
    emptyStateText: s__('Navigation|Groups you visit often will appear here.'),
  },
  computed: {
    isLoggedIn() {
      return Boolean(gon.current_username);
    },
    items() {
      return this.frecentGroups || [];
    },
  },
  created() {
    if (!this.isLoggedIn) {
      this.$emit('nothing-to-render');
    }
  },
  FREQUENTLY_VISITED_GROUPS_HANDLE,
};
</script>

<template>
  <frequent-items
    v-if="isLoggedIn"
    :loading="$apollo.queries.frecentGroups.loading"
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :items="items"
    view-all-items-icon="group"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="groupsPath"
    v-bind="$attrs"
    v-on="$listeners"
    @action="$emit('action', $options.FREQUENTLY_VISITED_GROUPS_HANDLE)"
  />
</template>
