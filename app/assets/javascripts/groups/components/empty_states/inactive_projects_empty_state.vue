<script>
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import { s__ } from '~/locale';
import { SEARCH_MINIMUM_LENGTH } from '../../constants';

export default {
  components: { ResourceListsEmptyState },
  SEARCH_MINIMUM_LENGTH,
  i18n: {
    title: s__('GroupsEmptyState|There are no inactive projects in this group'),
    description: s__('GroupsEmptyState|Projects that are no longer used are displayed here.'),
  },
  inject: ['emptyProjectsIllustration'],
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
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :svg-path="emptyProjectsIllustration"
    :search="search"
    :search-minimum-length="$options.SEARCH_MINIMUM_LENGTH"
  />
</template>
