<script>
import { s__ } from '~/locale';
import { MAX_FREQUENT_GROUPS_COUNT } from '~/super_sidebar/constants';
import FrequentItems from './frequent_items.vue';

export default {
  name: 'FrequentlyVisitedGroups',
  components: {
    FrequentItems,
  },
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
    :empty-state-text="$options.i18n.emptyStateText"
    :group-name="$options.i18n.groupName"
    :max-items="$options.MAX_FREQUENT_GROUPS_COUNT"
    :storage-key="storageKey"
    view-all-items-icon="group"
    :view-all-items-text="$options.i18n.viewAllText"
    :view-all-items-path="groupsPath"
    v-bind="$attrs"
    v-on="$listeners"
  />
</template>
