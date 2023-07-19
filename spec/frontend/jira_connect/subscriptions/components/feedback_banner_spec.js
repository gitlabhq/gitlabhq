import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FeedbackBanner from '~/jira_connect/subscriptions/components/feedback_banner.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('FeedbackBanner', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(FeedbackBanner);
  };

  const findBanner = () => wrapper.findComponent(GlBanner);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  beforeEach(() => {
    createComponent();
  });

  it('renders a banner with button', () => {
    expect(findBanner().props()).toMatchObject({
      title: FeedbackBanner.i18n.title,
      buttonText: FeedbackBanner.i18n.buttonText,
      buttonLink: FeedbackBanner.feedbackIssueUrl,
    });
  });

  it('uses localStorage with default value as false', () => {
    expect(findLocalStorageSync().props().value).toBe(false);
  });

  describe('when banner is dimsissed', () => {
    beforeEach(() => {
      findBanner().vm.$emit('close');
    });

    it('hides the banner', () => {
      expect(findBanner().exists()).toBe(false);
    });

    it('updates localStorage value to true', () => {
      expect(findLocalStorageSync().props().value).toBe(true);
    });
  });
});
