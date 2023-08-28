<script>
import OrganizationAvatar from './organization_avatar.vue';
import GroupsAndProjects from './groups_and_projects.vue';

export default {
  name: 'OrganizationShowApp',
  components: { OrganizationAvatar, GroupsAndProjects },
  props: {
    organization: {
      type: Object,
      required: true,
    },
    groupsAndProjectsOrganizationPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <organization-avatar :organization="organization" />
    <groups-and-projects
      :groups-and-projects-organization-path="groupsAndProjectsOrganizationPath"
    />
  </div>
</template>
