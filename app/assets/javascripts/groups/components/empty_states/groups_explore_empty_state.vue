<script>
import groupsEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';

export default {
  components: { ResourceListsEmptyState },
  groupsEmptyStateIllustration,
  props: {
    search: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <resource-lists-empty-state
    :title="s__('GroupsEmptyState|No public or internal groups')"
    :svg-path="$options.groupsEmptyStateIllustration"
    :search="search"
  />
</template>
