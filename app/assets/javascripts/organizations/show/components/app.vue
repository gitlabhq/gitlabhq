<script>
import OrganizationAvatar from './organization_avatar.vue';
import GroupsAndProjects from './groups_and_projects.vue';
import AssociationCounts from './association_counts.vue';

export default {
  name: 'OrganizationShowApp',
  components: { OrganizationAvatar, GroupsAndProjects, AssociationCounts },
  props: {
    organization: {
      type: Object,
      required: true,
    },
    groupsAndProjectsOrganizationPath: {
      type: String,
      required: true,
    },
    associationCounts: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <organization-avatar :organization="organization" />
    <association-counts
      :association-counts="associationCounts"
      :groups-and-projects-organization-path="groupsAndProjectsOrganizationPath"
    />
    <groups-and-projects
      :groups-and-projects-organization-path="groupsAndProjectsOrganizationPath"
    />
  </div>
</template>
