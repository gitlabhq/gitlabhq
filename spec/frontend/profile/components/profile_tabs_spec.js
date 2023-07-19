import projects from 'test_fixtures/api/users/projects/get.json';
import ProfileTabs from '~/profile/components/profile_tabs.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { getUserProjects } from '~/rest_api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { VISIBILITY_LEVEL_PUBLIC_STRING } from '~/visibility_level/constants';
import OverviewTab from '~/profile/components/overview_tab.vue';
import ActivityTab from '~/profile/components/activity_tab.vue';
import GroupsTab from '~/profile/components/groups_tab.vue';
import ContributedProjectsTab from '~/profile/components/contributed_projects_tab.vue';
import PersonalProjectsTab from '~/profile/components/personal_projects_tab.vue';
import StarredProjectsTab from '~/profile/components/starred_projects_tab.vue';
import SnippetsTab from '~/profile/components/snippets/snippets_tab.vue';
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
    it('passes correct props to `OverviewTab` component', async () => {
      getUserProjects.mockResolvedValueOnce({ data: projects });
      createComponent();
      await waitForPromises();

      expect(wrapper.findComponent(OverviewTab).props()).toMatchObject({
        personalProjects: convertObjectPropsToCamelCase(projects, { deep: true }),
        personalProjectsLoading: false,
      });
    });

    describe('when projects do not have `visibility` key', () => {
      it('sets visibility to public', async () => {
        const [{ visibility, ...projectWithoutVisibility }] = projects;

        getUserProjects.mockResolvedValueOnce({ data: [projectWithoutVisibility] });
        createComponent();
        await waitForPromises();

        expect(wrapper.findComponent(OverviewTab).props('personalProjects')[0].visibility).toBe(
          VISIBILITY_LEVEL_PUBLIC_STRING,
        );
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
