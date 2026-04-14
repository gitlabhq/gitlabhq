import {
  GlAvatar,
  GlDisclosureDropdown,
  GlEmptyState,
  GlKeysetPagination,
  GlLoadingIcon,
  GlModal,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import getGroupAchievementsResponse from 'test_fixtures/graphql/get_group_achievements_response.json';
import getGroupAchievementsEmptyResponse from 'test_fixtures/graphql/get_group_achievements_empty_response.json';
import getGroupAchievementsPaginatedResponse from 'test_fixtures/graphql/get_group_achievements_paginated_response.json';
import awardAchievementResponse from 'test_fixtures/graphql/award_achievement_response.json';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AchievementsApp from '~/achievements/components/achievements_app.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import getGroupAchievementsQuery from '~/achievements/components/graphql/get_group_achievements.query.graphql';
import deleteAchievementMutation from '~/achievements/components/graphql/delete_achievement.mutation.graphql';
import awardAchievementMutation from '~/achievements/components/graphql/award_achievement.mutation.graphql';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import AwardButton from '~/achievements/components/award_button.vue';

jest.mock('~/lib/logger');

Vue.use(VueApollo);

describe('Achievements app', () => {
  let wrapper;
  let fakeApollo;
  let queryHandler;

  const findAwardButton = () => wrapper.findComponent(AwardButton);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNewAchievementButton = () => wrapper.findByTestId('new-achievement-button');
  const findPagingControls = () => wrapper.findComponent(GlKeysetPagination);
  const findActionsDropdowns = () => wrapper.findAllComponents(GlDisclosureDropdown);
  const findDeleteModal = () => wrapper.findComponent(GlModal);

  const mountComponent = ({
    canAdminAchievement = true,
    canAwardAchievement = true,
    crudStub = false,
    mountFunction = shallowMountExtended,
    mutationHandler = null,
    queryHandlerOverride = null,
    queryResponse = getGroupAchievementsResponse,
    deleteMutationHandler = jest.fn().mockResolvedValue({
      data: {
        achievementsDelete: {
          achievement: { id: 'gid://gitlab/Achievements::Achievement/1' },
          errors: [],
        },
      },
    }),
  } = {}) => {
    queryHandler = queryHandlerOverride || jest.fn().mockResolvedValue(queryResponse);
    const handlers = [
      [getGroupAchievementsQuery, queryHandler],
      [deleteAchievementMutation, deleteMutationHandler],
    ];
    if (mutationHandler) {
      handlers.push([awardAchievementMutation, mutationHandler]);
    }
    fakeApollo = createMockApollo(handlers);
    wrapper = mountFunction(AchievementsApp, {
      provide: {
        canAdminAchievement,
        canAwardAchievement,
        groupFullPath: 'flightjs',
        gitlabLogoPath: '/assets/gitlab_logo.png',
      },
      apolloProvider: fakeApollo,
      mocks: {
        $toast: { show: jest.fn() },
      },
      stubs: {
        CrudComponent: crudStub,
        'router-link': true,
        'router-view': true,
      },
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

      expect(achievements).toHaveLength(3);
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
            getGroupAchievementsResponse.data.group.achievements.nodes[0].uniqueUsers.nodes[0],
            getGroupAchievementsResponse.data.group.achievements.nodes[0].uniqueUsers.nodes[1],
          ]),
        );
      });
    });

    describe('when a user is awarded', () => {
      const newUser = {
        id: 'gid://gitlab/User/99',
        avatarUrl: 'https://example.com/avatar.png',
        name: 'New User',
        username: 'newuser',
        webUrl: 'http://localhost/newuser',
        webPath: '/newuser',
        __typename: 'UserCore',
      };

      const updatedResponse = () => {
        const original = getGroupAchievementsResponse.data.group.achievements.nodes[0];
        return {
          data: {
            group: {
              ...getGroupAchievementsResponse.data.group,
              achievements: {
                ...getGroupAchievementsResponse.data.group.achievements,
                nodes: [
                  {
                    ...original,
                    uniqueUsers: {
                      ...original.uniqueUsers,
                      nodes: [...original.uniqueUsers.nodes, newUser],
                      count: original.uniqueUsers.count + 1,
                    },
                  },
                  ...getGroupAchievementsResponse.data.group.achievements.nodes.slice(1),
                ],
              },
            },
          },
        };
      };

      it('shows the newly awarded user without a page refresh', async () => {
        const mutationHandler = jest.fn().mockResolvedValue(awardAchievementResponse);
        const sequentialQueryHandler = jest
          .fn()
          .mockResolvedValueOnce(getGroupAchievementsResponse)
          .mockResolvedValue(updatedResponse());

        await mountComponent({
          mountFunction: mountExtended,
          mutationHandler,
          queryHandlerOverride: sequentialQueryHandler,
        });

        const awardButton = wrapper.findComponent(AwardButton);
        await awardButton.setData({ usersToAward: [{ id: 99 }] });
        await awardButton.findComponent(GlModal).vm.$emit('primary');

        await waitForPromises();

        const avatarList = wrapper
          .findAllComponents(CrudComponent)
          .at(0)
          .findComponent(UserAvatarList);

        expect(avatarList.props('items')).toEqual(
          expect.arrayContaining([expect.objectContaining({ id: newUser.id })]),
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

    describe('award button', () => {
      describe('when user can award_achievement', () => {
        it('should render', async () => {
          await mountComponent({ crudStub: { template: '<div><slot name="actions" /></div>' } });

          expect(findAwardButton().exists()).toBe(true);
        });
      });

      describe('when user can not award_achievement', () => {
        it('should not render', async () => {
          await mountComponent({
            canAwardAchievement: false,
            crudStub: { template: '<div><slot name="actions" /></div>' },
          });

          expect(findAwardButton().exists()).toBe(false);
        });
      });
    });

    describe('achievement actions dropdown', () => {
      describe('when user can admin_achievement', () => {
        it('renders a dropdown for each achievement', async () => {
          await mountComponent({ crudStub: { template: '<div><slot name="actions" /></div>' } });

          expect(findActionsDropdowns()).toHaveLength(3);
        });

        it('dropdown items include delete', async () => {
          await mountComponent({ crudStub: { template: '<div><slot name="actions" /></div>' } });

          const items = findActionsDropdowns().at(0).props('items');
          expect(items).toHaveLength(1);
          expect(items[0].text).toBe('Delete achievement');
          expect(items[0].action).toBeInstanceOf(Function);
        });
      });

      describe('when user cannot admin_achievement', () => {
        it('does not render the dropdown', async () => {
          await mountComponent({
            canAdminAchievement: false,
            crudStub: { template: '<div><slot name="actions" /></div>' },
          });

          expect(findActionsDropdowns()).toHaveLength(0);
        });
      });
    });

    describe('delete achievement', () => {
      it('renders a delete confirmation modal', async () => {
        await mountComponent();

        expect(findDeleteModal().exists()).toBe(true);
      });

      describe('when mutation returns errors', () => {
        it('shows the first error as a toast', async () => {
          const deleteMutationHandler = jest.fn().mockResolvedValue({
            data: {
              achievementsDelete: {
                achievement: null,
                errors: ['Name has already been taken'],
              },
            },
          });

          await mountComponent({
            crudStub: { template: '<div><slot name="actions" /></div>' },
            deleteMutationHandler,
          });

          const dropdownItems = findActionsDropdowns().at(0).props('items');
          dropdownItems[0].action();
          await nextTick();

          findDeleteModal().vm.$emit('primary');
          await waitForPromises();

          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Name has already been taken');
        });
      });

      describe('when mutation throws', () => {
        it('shows a failure toast', async () => {
          const deleteMutationHandler = jest.fn().mockRejectedValue(new Error('Network error'));

          await mountComponent({
            crudStub: { template: '<div><slot name="actions" /></div>' },
            deleteMutationHandler,
          });

          const dropdownItems = findActionsDropdowns().at(0).props('items');
          dropdownItems[0].action();
          await nextTick();

          findDeleteModal().vm.$emit('primary');
          await waitForPromises();

          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
            'Failed to delete achievement. Please try again.',
          );
        });
      });

      it('refetches achievements and shows a toast after successful delete', async () => {
        const firstAchievement = getGroupAchievementsResponse.data.group.achievements.nodes[0];
        const deleteMutationHandler = jest.fn().mockResolvedValue({
          data: {
            achievementsDelete: {
              achievement: { id: firstAchievement.id },
              errors: [],
            },
          },
        });

        await mountComponent({
          crudStub: { template: '<div><slot name="actions" /></div>' },
          deleteMutationHandler,
        });

        const dropdownItems = findActionsDropdowns().at(0).props('items');
        dropdownItems[0].action();
        await nextTick();

        findDeleteModal().vm.$emit('primary');
        await waitForPromises();

        expect(deleteMutationHandler).toHaveBeenCalledWith({
          input: { achievementId: firstAchievement.id },
        });
        expect(queryHandler).toHaveBeenCalledTimes(2);
        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Achievement has been deleted.');
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
