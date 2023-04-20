import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FeedbackBanner from '~/ci/artifacts/components/feedback_banner.vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import {
  I18N_FEEDBACK_BANNER_TITLE,
  I18N_FEEDBACK_BANNER_BUTTON,
  FEEDBACK_URL,
} from '~/ci/artifacts/constants';

const mockBannerImagePath = 'banner/image/path';

describe('Artifacts management feedback banner', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const findBanner = () => wrapper.findComponent(GlBanner);

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = shallowMount(FeedbackBanner, {
      provide: {
        artifactsManagementFeedbackImagePath: mockBannerImagePath,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  it('is displayed with the correct props', () => {
    createComponent();

    expect(findBanner().props()).toMatchObject({
      title: I18N_FEEDBACK_BANNER_TITLE,
      buttonText: I18N_FEEDBACK_BANNER_BUTTON,
      buttonLink: FEEDBACK_URL,
      svgPath: mockBannerImagePath,
    });
  });

  it('dismisses the callout when closed', () => {
    createComponent();

    findBanner().vm.$emit('close');

    expect(userCalloutDismissSpy).toHaveBeenCalled();
  });

  it('is not displayed once it has been dismissed', () => {
    createComponent({ shouldShowCallout: false });

    expect(findBanner().exists()).toBe(false);
  });
});
