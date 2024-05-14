import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import DetailsFeedback from '~/deployments/components/details_feedback.vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/graphql_shared/utils');

describe('~/deployments/components/details_feedback.vue', () => {
  let wrapper;
  let dismiss;
  let dismisserComponent;

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    dismiss = jest.fn();
    dismisserComponent = makeMockUserCalloutDismisser({
      dismiss,
      shouldShowCallout,
    });
    wrapper = shallowMount(DetailsFeedback, {
      stubs: {
        UserCalloutDismisser: dismisserComponent,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  it('shows an alert', () => {
    createComponent();
    expect(findAlert().exists()).toBe(true);
  });

  it('calls dismiss when the alert is dismissed', () => {
    createComponent();
    findAlert().vm.$emit('dismiss');
    expect(dismiss).toHaveBeenCalled();
  });

  it('links to the feedback issue', () => {
    createComponent();
    expect(findAlert().props()).toMatchObject({
      title: 'What would you like to see here?',
      primaryButtonText: 'Leave feedback',
      primaryButtonLink: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450700',
    });
  });

  it('hides the alert if already dismissed', () => {
    createComponent({ shouldShowCallout: false });
    expect(findAlert().exists()).toBe(false);
  });
});
