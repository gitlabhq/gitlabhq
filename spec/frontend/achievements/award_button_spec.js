import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlFormGroup, GlModal, GlSprintf } from '@gitlab/ui';
import awardAchievementResponse from 'test_fixtures/graphql/award_achievement_response.json';
import getGroupAchievementsResponse from 'test_fixtures/graphql/get_group_achievements_response.json';
import awardAchievementMutation from '~/achievements/components/graphql/award_achievement.mutation.graphql';
import getGroupAchievementsQuery from '~/achievements/components/graphql/get_group_achievements.query.graphql';
import AwardButton from '~/achievements/components/award_button.vue';
import GlobalUserSelect from '~/vue_shared/components/user_select/global_user_select.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

Vue.use(VueApollo);

describe('Award button', () => {
  let wrapper;
  let fakeApollo;

  const findAwardButton = () => wrapper.findComponent(GlButton);

  const modalStub = { show: jest.fn() };
  const GlModalStub = stubComponent(GlModal, { methods: modalStub });

  const awardAchievementHandler = jest.fn().mockResolvedValue(awardAchievementResponse);
  const groupAchievementsHandler = jest.fn().mockResolvedValue(getGroupAchievementsResponse);

  const mountComponent = () => {
    fakeApollo = createMockApollo([
      [awardAchievementMutation, awardAchievementHandler],
      [getGroupAchievementsQuery, groupAchievementsHandler],
    ]);
    fakeApollo.clients.defaultClient
      .watchQuery({ query: getGroupAchievementsQuery, variables: { groupFullPath: '' } })
      .subscribe();
    wrapper = shallowMountExtended(AwardButton, {
      apolloProvider: fakeApollo,
      propsData: {
        achievementId: 'gid://gitlab/Achievements::Achievement/123',
        achievementName: 'Legend',
      },
      stubs: {
        GlModal: GlModalStub,
        GlSprintf: {
          template: '<div><slot name="achievementName" /></div>',
        },
      },
    });

    return waitForPromises();
  };

  it('renders award button', () => {
    mountComponent();

    expect(findAwardButton().exists()).toBe(true);
  });

  describe('when award button clicked', () => {
    beforeEach(() => {
      mountComponent();

      findAwardButton().vm.$emit('click');
    });

    it('shows the modal', () => {
      expect(modalStub.show).toHaveBeenCalled();
    });

    it('shows the correct achievement message', () => {
      expect(wrapper.findComponent(GlSprintf).attributes('message')).toBe(
        "You're awarding users the %{achievementName} achievement",
      );
      expect(wrapper.findComponent(GlSprintf).html()).toContain('<b>Legend</b>');
    });

    it('renders a labelled form group for user selection', () => {
      const formGroup = wrapper.findComponent(GlFormGroup);

      expect(formGroup.exists()).toBe(true);
      expect(formGroup.attributes('label')).toBe('Users');
      expect(formGroup.attributes('label-for')).toBe('global_users_input');
    });

    it('passes input-id to GlobalUserSelect', () => {
      expect(wrapper.findComponent(GlobalUserSelect).props('inputId')).toBe('global_users_input');
    });

    it('calls mutation with expected users', async () => {
      wrapper.findComponent(GlobalUserSelect).vm.$emit('input', [{ id: 1 }, { id: 10 }]);
      wrapper.findComponent(GlModal).vm.$emit('primary');

      await waitForPromises();

      expect(awardAchievementHandler).toHaveBeenCalledTimes(2);

      expect(awardAchievementHandler).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({
          input: {
            achievementId: 'gid://gitlab/Achievements::Achievement/123',
            userId: 'gid://gitlab/User/1',
          },
        }),
      );
      expect(awardAchievementHandler).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({
          input: {
            achievementId: 'gid://gitlab/Achievements::Achievement/123',
            userId: 'gid://gitlab/User/10',
          },
        }),
      );
    });

    it('refetches achievements once after all awards complete', async () => {
      groupAchievementsHandler.mockClear();

      wrapper.findComponent(GlobalUserSelect).vm.$emit('input', [{ id: 1 }, { id: 10 }]);
      wrapper.findComponent(GlModal).vm.$emit('primary');
      await waitForPromises();

      expect(groupAchievementsHandler).toHaveBeenCalledTimes(1);
    });
  });
});
