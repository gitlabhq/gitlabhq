<script>
import { __, s__ } from '~/locale';
import { RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS } from '~/organizations/shared/constants';
import AssociationCountCard from './association_count_card.vue';

export default {
  name: 'AssociationCounts',
  i18n: {
    groups: __('Groups'),
    projects: __('Projects'),
    users: __('Users'),
    viewAll: __('View all'),
    manage: s__('Organization|Manage'),
  },
  components: { AssociationCountCard },
  props: {
    associationCounts: {
      type: Object,
      required: true,
    },
    groupsAndProjectsOrganizationPath: {
      type: String,
      required: true,
    },
    usersOrganizationPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    groupsLinkHref() {
      return `${this.groupsAndProjectsOrganizationPath}?display=${RESOURCE_TYPE_GROUPS}`;
    },
    projectsLinkHref() {
      return `${this.groupsAndProjectsOrganizationPath}?display=${RESOURCE_TYPE_PROJECTS}`;
    },
    associationCountCards() {
      return [
        {
          title: this.$options.i18n.groups,
          iconName: 'group',
          count: this.associationCounts.groups,
          linkHref: this.groupsLinkHref,
        },
        {
          title: this.$options.i18n.projects,
          iconName: 'project',
          count: this.associationCounts.projects,
          linkHref: this.projectsLinkHref,
        },
        {
          title: this.$options.i18n.users,
          iconName: 'users',
          count: this.associationCounts.users,
          linkText: this.$options.i18n.manage,
          linkHref: this.usersOrganizationPath,
        },
      ];
    },
  },
};
</script>

<template>
  <div class="gl-mt-5 gl-grid gl-gap-5 lg:gl-grid-cols-4">
    <association-count-card
      v-for="props in associationCountCards"
      :key="props.title"
      v-bind="props"
      class="gl-w-full"
    />
  </div>
</template>
