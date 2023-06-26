import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { mockTracking } from 'helpers/tracking_helper';
import TerraformNotification from '~/projects/terraform_notification/components/terraform_notification.vue';
import {
  EVENT_LABEL,
  DISMISS_EVENT,
  CLICK_EVENT,
} from '~/projects/terraform_notification/constants';

const terraformImagePath = '/path/to/image';

describe('TerraformNotificationBanner', () => {
  let wrapper;
  let trackingSpy;
  let userCalloutDismissSpy;

  const provideData = {
    terraformImagePath,
  };
  const findBanner = () => wrapper.findComponent(GlBanner);

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = shallowMount(TerraformNotification, {
      provide: provideData,
      stubs: {
        GlBanner,
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  });

  describe('when user has already dismissed the banner', () => {
    beforeEach(() => {
      createComponent({
        shouldShowCallout: false,
      });
    });
    it('should not render the banner', () => {
      expect(findBanner().exists()).toBe(false);
    });
  });

  describe("when user hasn't yet dismissed the banner", () => {
    it('should render the banner', () => {
      expect(findBanner().exists()).toBe(true);
    });
  });

  describe('when close button is clicked', () => {
    beforeEach(() => {
      findBanner().vm.$emit('close');
    });

    it('should send the dismiss event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, DISMISS_EVENT, {
        label: EVENT_LABEL,
      });
    });

    it('should call the dismiss callback', () => {
      expect(userCalloutDismissSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('when docs link is clicked', () => {
    beforeEach(() => {
      findBanner().vm.$emit('primary');
    });

    it('should send button click event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, CLICK_EVENT, {
        label: EVENT_LABEL,
      });
    });
  });
});
