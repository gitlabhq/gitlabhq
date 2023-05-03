import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RegistrationFeedbackBanner from '~/ci/runner/components/registration/registration_feedback_banner.vue';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

describe('Runner registration feeback banner', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const findUserCalloutDismisser = () => wrapper.findComponent(UserCalloutDismisser);
  const findBanner = () => wrapper.findComponent(GlBanner);

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = shallowMount(RegistrationFeedbackBanner, {
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  it('banner is shown', () => {
    createComponent();

    expect(findBanner().exists()).toBe(true);
  });

  it('dismisses the callout when closed', () => {
    createComponent();

    findBanner().vm.$emit('close');

    expect(userCalloutDismissSpy).toHaveBeenCalled();
  });

  it('sets feature name to create_runner_workflow_banner', () => {
    createComponent();

    expect(findUserCalloutDismisser().props('featureName')).toBe('create_runner_workflow_banner');
  });

  it('is not displayed once it has been dismissed', () => {
    createComponent({ shouldShowCallout: false });

    expect(findBanner().exists()).toBe(false);
  });
});
