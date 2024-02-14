import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlBadge } from '@gitlab/ui';
import getUserAchievementsEmptyResponse from 'test_fixtures/graphql/get_user_achievements_empty_response.json';
import getUserAchievementsLongResponse from 'test_fixtures/graphql/get_user_achievements_long_response.json';
import getUserAchievementsResponse from 'test_fixtures/graphql/get_user_achievements_with_avatar_and_description_response.json';
import getUserAchievementsPrivateGroupResponse from 'test_fixtures/graphql/get_user_achievements_from_private_group.json';
import getUserAchievementsNoAvatarResponse from 'test_fixtures/graphql/get_user_achievements_without_avatar_or_description_response.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UserAchievements, {
  MAX_VISIBLE_ACHIEVEMENTS,
} from '~/profile/components/user_achievements.vue';
import getUserAchievements from '~/profile/components//graphql/get_user_achievements.query.graphql';
import { getTimeago, timeagoLanguageCode } from '~/lib/utils/datetime_utility';
import { mountExtended } from 'helpers/vue_test_utils_helper';

const USER_ID = 123;
const ROOT_URL = 'https://gitlab.com/';
const PLACEHOLDER_URL = 'https://gitlab.com/assets/gitlab_logo.png';
const userAchievement1 = getUserAchievementsResponse.data.user.userAchievements.nodes[0];

Vue.use(VueApollo);

describe('UserAchievements', () => {
  let wrapper;

  const getUserAchievementsQueryHandler = jest.fn().mockResolvedValue(getUserAchievementsResponse);
  const achievement = () => wrapper.findByTestId('user-achievement');

  const createComponent = ({ queryHandler = getUserAchievementsQueryHandler } = {}) => {
    const fakeApollo = createMockApollo([[getUserAchievements, queryHandler]]);

    wrapper = mountExtended(UserAchievements, {
      apolloProvider: fakeApollo,
      provide: {
        rootUrl: ROOT_URL,
        userId: USER_ID,
      },
    });
  };

  it('renders no achievements on reject', async () => {
    createComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });

    await waitForPromises();

    expect(wrapper.findAllByTestId('user-achievement').length).toBe(0);
  });

  it('renders no achievements when none are present', async () => {
    createComponent({
      queryHandler: jest.fn().mockResolvedValue(getUserAchievementsEmptyResponse),
    });

    await waitForPromises();

    expect(wrapper.findAllByTestId('user-achievement').length).toBe(0);
  });

  it(`only renders ${MAX_VISIBLE_ACHIEVEMENTS} achievements when more are present`, async () => {
    createComponent({ queryHandler: jest.fn().mockResolvedValue(getUserAchievementsLongResponse) });

    await waitForPromises();

    expect(getUserAchievementsLongResponse.data.user.userAchievements.nodes.length).toBeGreaterThan(
      MAX_VISIBLE_ACHIEVEMENTS,
    );
    expect(wrapper.findAllByTestId('user-achievement').length).toBe(MAX_VISIBLE_ACHIEVEMENTS);
  });

  it('renders count for achievements awarded more than once', async () => {
    createComponent({ queryHandler: jest.fn().mockResolvedValue(getUserAchievementsLongResponse) });

    await waitForPromises();

    expect(achievement().findComponent(GlBadge).text()).toBe('2x');
  });

  it('renders correctly if the achievement is from a private namespace', async () => {
    createComponent({
      queryHandler: jest.fn().mockResolvedValue(getUserAchievementsPrivateGroupResponse),
    });

    await waitForPromises();

    const userAchievement =
      getUserAchievementsPrivateGroupResponse.data.user.userAchievements.nodes[0];

    expect(achievement().text()).toContain(userAchievement.achievement.name);
    expect(achievement().text()).toContain(
      `Awarded ${getTimeago().format(
        userAchievement.createdAt,
        timeagoLanguageCode,
      )} by a private namespace`,
    );
  });

  it('renders achievement correctly', async () => {
    createComponent();

    await waitForPromises();

    expect(achievement().text()).toContain(userAchievement1.achievement.name);
    expect(achievement().text()).toContain(
      `Awarded ${getTimeago().format(userAchievement1.createdAt, timeagoLanguageCode)} by`,
    );
    expect(achievement().text()).toContain(userAchievement1.achievement.namespace.fullPath);
    expect(achievement().text()).toContain(userAchievement1.achievement.description);
    expect(achievement().find('img').attributes('src')).toBe(
      userAchievement1.achievement.avatarUrl,
    );
  });

  it('renders a placeholder when no avatar is present', async () => {
    gon.gitlab_logo = PLACEHOLDER_URL;
    createComponent({
      queryHandler: jest.fn().mockResolvedValue(getUserAchievementsNoAvatarResponse),
    });

    await waitForPromises();

    expect(achievement().find('img').attributes('src')).toBe(PLACEHOLDER_URL);
  });

  it('does not render a description when none is present', async () => {
    gon.gitlab_logo = PLACEHOLDER_URL;
    createComponent({
      queryHandler: jest.fn().mockResolvedValue(getUserAchievementsNoAvatarResponse),
    });

    await waitForPromises();

    expect(wrapper.findAllByTestId('achievement-description').length).toBe(0);
  });
});
