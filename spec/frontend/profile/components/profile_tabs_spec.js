import ProfileTabs from '~/profile/components/profile_tabs.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import OverviewTab from '~/profile/components/overview_tab.vue';
import ActivityTab from '~/profile/components/activity_tab.vue';
import GroupsTab from '~/profile/components/groups_tab.vue';
import ContributedProjectsTab from '~/profile/components/contributed_projects_tab.vue';
import PersonalProjectsTab from '~/profile/components/personal_projects_tab.vue';
import StarredProjectsTab from '~/profile/components/starred_projects_tab.vue';
import SnippetsTab from '~/profile/components/snippets_tab.vue';
import FollowersTab from '~/profile/components/followers_tab.vue';
import FollowingTab from '~/profile/components/following_tab.vue';

describe('ProfileTabs', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ProfileTabs);
  };

  it.each([
    OverviewTab,
    ActivityTab,
    GroupsTab,
    ContributedProjectsTab,
    PersonalProjectsTab,
    StarredProjectsTab,
    SnippetsTab,
    FollowersTab,
    FollowingTab,
  ])('renders $i18n.title tab', (tab) => {
    createComponent();

    expect(wrapper.findComponent(tab).exists()).toBe(true);
  });
});
