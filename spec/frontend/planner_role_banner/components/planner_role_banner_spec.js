import { GlBanner, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import PlanRoleBanner from '~/planner_role_banner/components/planner_role_banner.vue';

describe('Planner role banner', () => {
  let wrapper;
  const userCalloutDismissSpy = jest.fn();

  const createWrapper = (shouldShowCallout) => {
    wrapper = shallowMount(PlanRoleBanner, {
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const findGlBanner = () => wrapper.findComponent(GlBanner);
  const findGlSprintf = () => wrapper.findComponent(GlSprintf);

  it('renders the banner', () => {
    createWrapper(true);

    expect(findGlBanner().props('title')).toBe('New Planner role');
    expect(findGlSprintf().attributes('message')).toBe(
      'The Planner role is a hybrid of the existing Guest and Reporter roles but designed for users who need access to planning workflows. For more information about the new role, see %{blogLinkStart}our blog%{blogLinkEnd} or %{learnMoreStart}learn more about roles and permissions%{learnMoreEnd}.',
    );
  });

  it('does not render the banner', () => {
    createWrapper(false);

    expect(findGlBanner().exists()).toBe(false);
  });
});
