<script>
import { GlTabs } from '@gitlab/ui';

import { getUserProjects } from '~/rest_api';
import { s__ } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import OverviewTab from './overview_tab.vue';
import ActivityTab from './activity_tab.vue';
import GroupsTab from './groups_tab.vue';
import ContributedProjectsTab from './contributed_projects_tab.vue';
import PersonalProjectsTab from './personal_projects_tab.vue';
import StarredProjectsTab from './starred_projects_tab.vue';
import SnippetsTab from './snippets_tab.vue';
import FollowersTab from './followers_tab.vue';
import FollowingTab from './following_tab.vue';

export default {
  i18n: {
    personalProjectsErrorMessage: s__(
      'UserProfile|An error occurred loading the personal projects. Please refresh the page to try again.',
    ),
  },
  components: {
    GlTabs,
    OverviewTab,
    ActivityTab,
    GroupsTab,
    ContributedProjectsTab,
    PersonalProjectsTab,
    StarredProjectsTab,
    SnippetsTab,
    FollowersTab,
    FollowingTab,
  },
  tabs: [
    {
      key: 'overview',
      component: OverviewTab,
    },
    {
      key: 'activity',
      component: ActivityTab,
    },
    {
      key: 'groups',
      component: GroupsTab,
    },
    {
      key: 'contributedProjects',
      component: ContributedProjectsTab,
    },
    {
      key: 'personalProjects',
      component: PersonalProjectsTab,
    },
    {
      key: 'starredProjects',
      component: StarredProjectsTab,
    },
    {
      key: 'snippets',
      component: SnippetsTab,
    },
    {
      key: 'followers',
      component: FollowersTab,
    },
    {
      key: 'following',
      component: FollowingTab,
    },
  ],
  inject: ['userId'],
  data() {
    return {
      personalProjectsLoading: true,
      personalProjects: [],
    };
  },
  async mounted() {
    try {
      const response = await getUserProjects(this.userId, { per_page: 10 });
      this.personalProjects = convertObjectPropsToCamelCase(response.data, { deep: true });
      this.personalProjectsLoading = false;
    } catch (error) {
      createAlert({ message: this.$options.i18n.personalProjectsErrorMessage });
    }
  },
};
</script>

<template>
  <gl-tabs nav-class="gl-bg-gray-10" align="center">
    <component
      :is="component"
      v-for="{ key, component } in $options.tabs"
      :key="key"
      class="container-fluid container-limited gl-text-left"
      :personal-projects="personalProjects"
      :personal-projects-loading="personalProjectsLoading"
    />
  </gl-tabs>
</template>
