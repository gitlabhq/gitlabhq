import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlFormGroup, GlFormInput, GlModal, GlSprintf } from '@gitlab/ui';
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
      const formGroups = wrapper.findAllComponents(GlFormGroup);
      const userFormGroup = formGroups.at(0);

      expect(userFormGroup.exists()).toBe(true);
      expect(userFormGroup.attributes('label')).toBe('Users');
      expect(userFormGroup.attributes('label-for')).toBe('global_users_input');
    });

    it('renders a labelled form group for award message', () => {
      const formGroups = wrapper.findAllComponents(GlFormGroup);
      const messageFormGroup = formGroups.at(1);

      expect(messageFormGroup.exists()).toBe(true);
      expect(messageFormGroup.attributes('label')).toBe('Award message');
      expect(messageFormGroup.attributes('label-for')).toBe('award_message_input');
    });

    it('passes input-id to GlobalUserSelect', () => {
      expect(wrapper.findComponent(GlobalUserSelect).props('inputId')).toBe('global_users_input');
    });

    it('calls mutation with expected users', async () => {
      wrapper.findComponent(GlobalUserSelect).vm.$emit('input', [{ id: 1 }, { id: 10 }]);
      wrapper.findComponent(GlModal).vm.$emit('primary');

      await waitForPromises();

      expect(awardAchievementHandler).toHaveBeenCalledTimes(2);

      expect(awardAchievementHandler).toHaveBeenNthCalledWith(1, {
        input: {
          achievementId: 'gid://gitlab/Achievements::Achievement/123',
          userId: 'gid://gitlab/User/1',
        },
      });
      expect(awardAchievementHandler).toHaveBeenNthCalledWith(2, {
        input: {
          achievementId: 'gid://gitlab/Achievements::Achievement/123',
          userId: 'gid://gitlab/User/10',
        },
      });
    });

    it('refetches achievements once after all awards complete', async () => {
      groupAchievementsHandler.mockClear();

      wrapper.findComponent(GlobalUserSelect).vm.$emit('input', [{ id: 1 }, { id: 10 }]);
      wrapper.findComponent(GlModal).vm.$emit('primary');
      await waitForPromises();

      expect(groupAchievementsHandler).toHaveBeenCalledTimes(1);
    });

    it('resets modal values after all awards complete', async () => {
      wrapper.findComponent(GlobalUserSelect).vm.$emit('input', [{ id: 1 }]);
      wrapper.findComponent(GlFormInput).vm.$emit('input', 'Great work!');
      await nextTick();

      wrapper.findComponent(GlModal).vm.$emit('primary');
      await waitForPromises();

      expect(wrapper.vm.usersToAward).toEqual([]);
      expect(wrapper.vm.awardMessage).toBe('');
    });

    it('includes award message in mutation when provided', async () => {
      awardAchievementHandler.mockClear();

      wrapper.findComponent(GlFormInput).vm.$emit('input', 'Great work!');
      await nextTick();

      wrapper.findComponent(GlobalUserSelect).vm.$emit('input', [{ id: 1 }]);
      wrapper.findComponent(GlModal).vm.$emit('primary');

      await waitForPromises();

      expect(awardAchievementHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          input: {
            achievementId: 'gid://gitlab/Achievements::Achievement/123',
            userId: 'gid://gitlab/User/1',
            awardMessage: 'Great work!',
          },
        }),
      );
    });
  });
});
