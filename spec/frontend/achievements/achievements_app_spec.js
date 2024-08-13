import { GlAvatar, GlEmptyState, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import getGroupAchievementsResponse from 'test_fixtures/graphql/get_group_achievements_response.json';
import getGroupAchievementsEmptyResponse from 'test_fixtures/graphql/get_group_achievements_empty_response.json';
import getGroupAchievementsPaginatedResponse from 'test_fixtures/graphql/get_group_achievements_paginated_response.json';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AchievementsApp from '~/achievements/components/achievements_app.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import getGroupAchievementsQuery from '~/achievements/components/graphql/get_group_achievements.query.graphql';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

Vue.use(VueApollo);

describe('Achievements app', () => {
  let wrapper;
  let fakeApollo;
  let queryHandler;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNewAchievementButton = () => wrapper.findByTestId('new-achievement-button');
  const findPagingControls = () => wrapper.findComponent(GlKeysetPagination);

  const mountComponent = ({
    canAdminAchievement = true,
    mountFunction = shallowMountExtended,
    queryResponse = getGroupAchievementsResponse,
  } = {}) => {
    queryHandler = jest.fn().mockResolvedValue(queryResponse);
    fakeApollo = createMockApollo([[getGroupAchievementsQuery, queryHandler]]);
    wrapper = mountFunction(AchievementsApp, {
      provide: {
        canAdminAchievement,
        groupFullPath: 'flightjs',
        gitlabLogoPath: '/assets/gitlab_logo.png',
      },
      apolloProvider: fakeApollo,
      stubs: ['router-link', 'router-view'],
    });
    return waitForPromises();
  };

  it('should render loading state', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('on successful load', () => {
    it('should render the right number of achievements', async () => {
      await mountComponent();

      const achievements = wrapper.findAllComponents(CrudComponent);

      expect(achievements.length).toBe(3);
    });

    it('should render the correct achievement name and avatar (when present)', async () => {
      await mountComponent({ mountFunction: mountExtended });

      const achievements = wrapper.findAllComponents(CrudComponent);

      expect(achievements.at(0).text()).toContain('Legend');
      expect(achievements.at(0).findComponent(GlAvatar).props('src')).toMatch(/\/dk.png$/);
    });

    it('should render the correct achievement name and avatar (when not present)', async () => {
      await mountComponent({ mountFunction: mountExtended });

      const achievements = wrapper.findAllComponents(CrudComponent);

      expect(achievements.at(1).text()).toContain('Star');
      expect(achievements.at(1).findComponent(GlAvatar).props('src')).toBe(
        '/assets/gitlab_logo.png',
      );
    });

    describe('when not awarded', () => {
      it('should render not yet awarded message', async () => {
        await mountComponent({ mountFunction: mountExtended });

        const achievements = wrapper.findAllComponents(CrudComponent);

        expect(achievements.at(1).text()).toContain('Not yet awarded');
      });
    });

    describe('when awarded', () => {
      it('should mount user avatar list with expected props', async () => {
        await mountComponent({ mountFunction: mountExtended });

        const achievements = wrapper.findAllComponents(CrudComponent);
        const avatarList = achievements.at(0).findComponent(UserAvatarList);

        expect(avatarList.exists()).toBe(true);
        expect(avatarList.props('items')).toEqual(
          expect.arrayContaining([
            getGroupAchievementsResponse.data.group.achievements.nodes[0].userAchievements.nodes[0]
              .user,
            getGroupAchievementsResponse.data.group.achievements.nodes[0].userAchievements.nodes[1]
              .user,
          ]),
        );
      });
    });

    describe('new achievement button', () => {
      describe('when user can admin_achievement', () => {
        it('should render', async () => {
          await mountComponent();

          expect(findNewAchievementButton().exists()).toBe(true);
        });
      });

      describe('when user can not admin_achievement', () => {
        it('should not render', async () => {
          await mountComponent({ canAdminAchievement: false });

          expect(findNewAchievementButton().exists()).toBe(false);
        });
      });
    });

    describe('with no achievements', () => {
      it('should render the empty state', async () => {
        await mountComponent({ queryResponse: getGroupAchievementsEmptyResponse });

        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('with multiple pages', () => {
      it('should render paging controls', async () => {
        await mountComponent({ queryResponse: getGroupAchievementsPaginatedResponse });

        expect(findPagingControls().exists()).toBe(true);
      });

      describe('when the next page is selected', () => {
        it('should pass the end cursor', async () => {
          await mountComponent({ queryResponse: getGroupAchievementsPaginatedResponse });
          findPagingControls().vm.$emit('next', 'foo');
          await waitForPromises();

          expect(queryHandler).toHaveBeenCalledWith({
            after: null,
            before: null,
            first: 20,
            groupFullPath: 'flightjs',
            last: null,
          });
          expect(queryHandler).toHaveBeenCalledWith({
            after: 'foo',
            before: null,
            first: 20,
            groupFullPath: 'flightjs',
            last: null,
          });
        });
      });
    });
  });
});
