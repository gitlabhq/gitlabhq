import { nextTick } from 'vue';
import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import MergeRequestExperienceSurveyApp from '~/surveys/merge_request_experience/app.vue';
import SatisfactionRate from '~/surveys/components/satisfaction_rate.vue';

describe('MergeRequestExperienceSurveyApp', () => {
  let trackingSpy;
  let wrapper;
  let dismiss;
  let dismisserComponent;

  const findCloseButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .filter((button) => button.attributes('aria-label') === 'Close')
      .at(0);

  const createWrapper = ({ shouldShowCallout = true } = {}) => {
    dismiss = jest.fn();
    dismisserComponent = makeMockUserCalloutDismisser({
      dismiss,
      shouldShowCallout,
    });
    wrapper = shallowMountExtended(MergeRequestExperienceSurveyApp, {
      propsData: {
        accountAge: 0,
      },
      stubs: {
        UserCalloutDismisser: dismisserComponent,
        GlSprintf,
      },
    });
  };

  describe('when user callout is visible', () => {
    beforeEach(() => {
      createWrapper();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('shows survey', async () => {
      expect(wrapper.html()).toContain('Overall, how satisfied are you with merge requests?');
      expect(wrapper.findComponent(SatisfactionRate).exists()).toBe(true);
      expect(wrapper.emitted().close).toBe(undefined);
    });

    it('triggers user callout on close', async () => {
      findCloseButton().vm.$emit('click');
      expect(dismiss).toHaveBeenCalledTimes(1);
    });

    it('emits close event on close button click', async () => {
      findCloseButton().vm.$emit('click');
      expect(wrapper.emitted()).toMatchObject({ close: [[]] });
    });

    it('applies correct feature name for user callout', () => {
      expect(wrapper.findComponent(dismisserComponent).props('featureName')).toBe(
        'mr_experience_survey',
      );
    });

    it('dismisses user callout on survey rate', async () => {
      const rate = wrapper.findComponent(SatisfactionRate);
      expect(dismiss).not.toHaveBeenCalled();
      rate.vm.$emit('rate', 5);
      expect(dismiss).toHaveBeenCalledTimes(1);
    });

    it('steps through survey steps', async () => {
      const rate = wrapper.findComponent(SatisfactionRate);
      rate.vm.$emit('rate', 5);
      await nextTick();
      expect(wrapper.text()).toContain(
        'How satisfied are you with speed/performance of merge requests?',
      );
    });

    it('tracks survey rates', async () => {
      const rate = wrapper.findComponent(SatisfactionRate);
      rate.vm.$emit('rate', 5);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'survey:mr_experience', {
        value: 5,
        label: 'overall',
        extra: {
          accountAge: 0,
        },
      });
      rate.vm.$emit('rate', 4);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'survey:mr_experience', {
        value: 4,
        label: 'performance',
        extra: {
          accountAge: 0,
        },
      });
    });

    it('shows legal note', async () => {
      expect(wrapper.text()).toContain(
        'By continuing, you acknowledge that responses will be used to improve GitLab and in accordance with the GitLab Privacy Policy.',
      );
    });

    it('hides legal note after first step', async () => {
      const rate = wrapper.findComponent(SatisfactionRate);
      rate.vm.$emit('rate', 5);
      await nextTick();
      expect(wrapper.text()).not.toContain(
        'By continuing, you acknowledge that responses will be used to improve GitLab and in accordance with the GitLab Privacy Policy.',
      );
    });

    it('shows disappearing thanks message', async () => {
      const rate = wrapper.findComponent(SatisfactionRate);
      rate.vm.$emit('rate', 5);
      await nextTick();
      rate.vm.$emit('rate', 5);
      await nextTick();
      expect(wrapper.text()).toContain('Thank you for your feedback!');
      expect(wrapper.emitted()).toMatchObject({});
      jest.runOnlyPendingTimers();
      expect(wrapper.emitted()).toMatchObject({ close: [[]] });
    });
  });

  describe('when user callout is hidden', () => {
    beforeEach(() => {
      createWrapper({ shouldShowCallout: false });
    });

    it('emits close event', async () => {
      expect(wrapper.emitted()).toMatchObject({ close: [[]] });
    });
  });

  describe('when Escape key is pressed', () => {
    beforeEach(() => {
      createWrapper();
      const event = new KeyboardEvent('keyup', { key: 'Escape' });
      document.dispatchEvent(event);
    });

    it('emits close event', async () => {
      expect(wrapper.emitted()).toMatchObject({ close: [[]] });
      expect(dismiss).toHaveBeenCalledTimes(1);
    });
  });
});
