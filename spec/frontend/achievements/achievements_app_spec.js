import { GlEmptyState, GlKeysetPagination, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import getGroupAchievementsResponse from 'test_fixtures/graphql/get_group_achievements_response.json';
import getGroupAchievementsEmptyResponse from 'test_fixtures/graphql/get_group_achievements_empty_response.json';
import getGroupAchievementsPaginatedResponse from 'test_fixtures/graphql/get_group_achievements_paginated_response.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AchievementsApp from '~/achievements/components/achievements_app.vue';
import getGroupAchievementsQuery from '~/achievements/components/graphql/get_group_achievements.query.graphql';

Vue.use(VueApollo);

describe('Achievements app', () => {
  let wrapper;
  let fakeApollo;
  let queryHandler;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNewAchievementButton = () => wrapper.findByTestId('new-achievement-button');
  const findPagingControls = () => wrapper.findComponent(GlKeysetPagination);
  const findTable = () => wrapper.findComponent(GlTableLite);

  const mountComponent = ({
    canAdminAchievement = true,
    queryResponse = getGroupAchievementsResponse,
  } = {}) => {
    queryHandler = jest.fn().mockResolvedValue(queryResponse);
    fakeApollo = createMockApollo([[getGroupAchievementsQuery, queryHandler]]);
    wrapper = shallowMountExtended(AchievementsApp, {
      provide: {
        canAdminAchievement,
        groupFullPath: 'flightjs',
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
    it('should render table with expected props', async () => {
      await mountComponent();

      const { items } = findTable().vm.$attrs;

      expect(findTable().exists()).toBe(true);
      expect(items).toContainEqual(expect.objectContaining({ name: 'Hero' }));
      expect(items).toContainEqual(expect.objectContaining({ name: 'Star' }));
      expect(items).toContainEqual(expect.objectContaining({ name: 'Legend' }));
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
