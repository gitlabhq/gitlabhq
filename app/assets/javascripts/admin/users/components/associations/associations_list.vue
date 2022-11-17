<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import AssociationsListItem from './associations_list_item.vue';

export default {
  i18n: {
    errorMessage: s__(
      "AdminUsers|An error occurred while fetching this user's contributions, and the request cannot return the number of issues, merge requests, groups, and projects linked to this user. If you proceed with deleting the user, all their contributions will still be deleted.",
    ),
  },
  components: {
    AssociationsListItem,
    GlAlert,
  },
  props: {
    associationsCount: {
      type: [Object, Error],
      required: true,
    },
  },
  computed: {
    hasError() {
      return this.associationsCount instanceof Error;
    },
    hasAssociations() {
      return Object.values(this.associationsCount).some((count) => count > 0);
    },
  },
};
</script>

<template>
  <gl-alert v-if="hasError" class="gl-mb-5" variant="danger" :dismissible="false">{{
    $options.i18n.errorMessage
  }}</gl-alert>
  <ul v-else-if="hasAssociations" class="gl-mb-5">
    <associations-list-item
      v-if="associationsCount.groups_count"
      :message="n__('%{count} group', '%{count} groups', associationsCount.groups_count)"
      :count="associationsCount.groups_count"
    />
    <associations-list-item
      v-if="associationsCount.projects_count"
      :message="n__('%{count} project', '%{count} projects', associationsCount.projects_count)"
      :count="associationsCount.projects_count"
    />
    <associations-list-item
      v-if="associationsCount.issues_count"
      :message="n__('%{count} issue', '%{count} issues', associationsCount.issues_count)"
      :count="associationsCount.issues_count"
    />
    <associations-list-item
      v-if="associationsCount.merge_requests_count"
      :message="
        n__(
          '%{count} merge request',
          '%{count} merge requests',
          associationsCount.merge_requests_count,
        )
      "
      :count="associationsCount.merge_requests_count"
    />
  </ul>
</template>
