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
    :title="s__('GroupsEmptyState|A group is a collection of several projects')"
    :description="
      s__(
        'GroupsEmptyState|If you organize your projects under a group, it works like a folder. You can manage your group member\'s permissions and access to each project in the group.',
      )
    "
    :svg-path="$options.groupsEmptyStateIllustration"
    :search="search"
  />
</template>
