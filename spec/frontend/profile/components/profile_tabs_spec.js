import projects from 'test_fixtures/api/users/projects/get.json';
import ProfileTabs from '~/profile/components/profile_tabs.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { getUserProjects } from '~/rest_api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OverviewTab from '~/profile/components/overview_tab.vue';
import ActivityTab from '~/profile/components/activity_tab.vue';
import GroupsTab from '~/profile/components/groups_tab.vue';
import ContributedProjectsTab from '~/profile/components/contributed_projects_tab.vue';
import PersonalProjectsTab from '~/profile/components/personal_projects_tab.vue';
import StarredProjectsTab from '~/profile/components/starred_projects_tab.vue';
import SnippetsTab from '~/profile/components/snippets_tab.vue';
import FollowersTab from '~/profile/components/followers_tab.vue';
import FollowingTab from '~/profile/components/following_tab.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/alert');
jest.mock('~/rest_api');

describe('ProfileTabs', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ProfileTabs, {
      provide: {
        userId: '1',
      },
    });
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

  describe('when personal projects API request is loading', () => {
    beforeEach(() => {
      getUserProjects.mockReturnValueOnce(new Promise(() => {}));
      createComponent();
    });

    it('passes correct props to `OverviewTab` component', () => {
      expect(wrapper.findComponent(OverviewTab).props()).toEqual({
        personalProjects: [],
        personalProjectsLoading: true,
      });
    });
  });

  describe('when personal projects API request is successful', () => {
    beforeEach(async () => {
      getUserProjects.mockResolvedValueOnce({ data: projects });
      createComponent();
      await waitForPromises();
    });

    it('passes correct props to `OverviewTab` component', () => {
      expect(wrapper.findComponent(OverviewTab).props()).toMatchObject({
        personalProjects: convertObjectPropsToCamelCase(projects, { deep: true }),
        personalProjectsLoading: false,
      });
    });
  });

  describe('when personal projects API request is not successful', () => {
    beforeEach(() => {
      getUserProjects.mockRejectedValueOnce();
      createComponent();
    });

    it('calls `createAlert`', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: ProfileTabs.i18n.personalProjectsErrorMessage,
      });
    });
  });
});
