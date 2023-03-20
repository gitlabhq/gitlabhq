<script>
import { GlTabs } from '@gitlab/ui';

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
};
</script>

<template>
  <gl-tabs nav-class="gl-bg-gray-10" align="center">
    <component
      :is="component"
      v-for="{ key, component } in $options.tabs"
      :key="key"
      class="container-fluid container-limited"
    />
  </gl-tabs>
</template>
