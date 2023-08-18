<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import groupsQuery from '../graphql/queries/groups.query.graphql';
import { formatGroups } from '../utils';

export default {
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred loading the groups. Please refresh the page to try again.',
    ),
  },
  components: { GlLoadingIcon, GroupsList },
  data() {
    return {
      groups: [],
    };
  },
  apollo: {
    groups: {
      query: groupsQuery,
      update(data) {
        return formatGroups(data.organization.groups.nodes);
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groups.loading;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <groups-list v-else :groups="groups" show-group-icon />
</template>
