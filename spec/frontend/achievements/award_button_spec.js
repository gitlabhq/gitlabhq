import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import awardAchievementResponse from 'test_fixtures/graphql/award_achievement_response.json';
import awardAchievementMutation from '~/achievements/components/graphql/award_achievement.mutation.graphql';
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

  const mountComponent = () => {
    const mockMutationResponse = jest.fn().mockResolvedValue(awardAchievementResponse);
    fakeApollo = createMockApollo([[awardAchievementMutation, mockMutationResponse]]);
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

    it('shows the correct message', () => {
      expect(wrapper.findComponent(GlSprintf).attributes('message')).toBe(
        "You're awarding users the %{achievementName} achievement",
      );
      expect(wrapper.findComponent(GlSprintf).html()).toContain('<b>Legend</b>');
    });

    it('calls mutation with expected users', () => {
      wrapper.findComponent(GlobalUserSelect).vm.$emit('input', [{ id: 1 }, { id: 10 }]);

      const mutateSpy = jest.spyOn(wrapper.vm.$apollo, 'mutate');
      wrapper.findComponent(GlModal).vm.$emit('primary');

      expect(mutateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              achievementId: 'gid://gitlab/Achievements::Achievement/123',
              userId: 'gid://gitlab/User/1',
            },
          },
        }),
      );
      expect(mutateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              achievementId: 'gid://gitlab/Achievements::Achievement/123',
              userId: 'gid://gitlab/User/10',
            },
          },
        }),
      );
    });
  });
});
