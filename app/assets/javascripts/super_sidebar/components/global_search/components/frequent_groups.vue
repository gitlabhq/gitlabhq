<script>
import { s__ } from '~/locale';
import { MAX_FREQUENT_GROUPS_COUNT } from '~/super_sidebar/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import currentUserFrecentGroupsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_groups.query.graphql';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedGroups',
  apollo: {
    frecentGroups: {
      query: currentUserFrecentGroupsQuery,
      skip() {
        return !this.glFeatures.frecentNamespacesSuggestions;
      },
    },
  },
  components: {
    FrequentItems,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['groupsPath'],
  data() {
    const username = gon.current_username;

    return {
      storageKey: username ? `${username}/frequent-groups` : null,
    };
  },
  i18n: {
    groupName: s__('Navigation|Frequently visited groups'),
    viewAllText: s__('Navigation|View all my groups'),
    emptyStateText: s__('Navigation|Groups you visit often will appear here.'),
  },
  MAX_FREQUENT_GROUPS_COUNT,
};
</script>

<template>
  <frequent-items
    :loading="$apollo.queries.frecentGroups.loading"
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :max-items="$options.MAX_FREQUENT_GROUPS_COUNT"
    :storage-key="storageKey"
    :items="frecentGroups"
    view-all-items-icon="group"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="groupsPath"
    v-bind="$attrs"
    v-on="$listeners"
  />
</template>
