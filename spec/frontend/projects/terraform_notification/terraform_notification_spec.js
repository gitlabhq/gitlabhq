import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { setCookie, parseBoolean } from '~/lib/utils/common_utils';
import TerraformNotification from '~/projects/terraform_notification/components/terraform_notification.vue';
import {
  EVENT_LABEL,
  DISMISS_EVENT,
  CLICK_EVENT,
} from '~/projects/terraform_notification/constants';

jest.mock('~/lib/utils/common_utils');

const terraformImagePath = '/path/to/image';
const bannerDismissedKey = 'terraform_notification_dismissed';

describe('TerraformNotificationBanner', () => {
  let wrapper;
  let trackingSpy;

  const provideData = {
    terraformImagePath,
    bannerDismissedKey,
  };
  const findBanner = () => wrapper.findComponent(GlBanner);

  beforeEach(() => {
    wrapper = shallowMount(TerraformNotification, {
      provide: provideData,
      stubs: { GlBanner },
    });
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    parseBoolean.mockReturnValue(false);
    unmockTracking();
  });

  describe('when the dismiss cookie is not set', () => {
    it('should render the banner', () => {
      expect(findBanner().exists()).toBe(true);
    });
  });

  describe('when close button is clicked', () => {
    beforeEach(async () => {
      await findBanner().vm.$emit('close');
    });

    it('should set the cookie with the bannerDismissedKey', () => {
      expect(setCookie).toHaveBeenCalledWith(bannerDismissedKey, true);
    });

    it('should send the dismiss event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, DISMISS_EVENT, {
        label: EVENT_LABEL,
      });
    });

    it('should remove the banner', () => {
      expect(findBanner().exists()).toBe(false);
    });
  });

  describe('when docs link is clicked', () => {
    beforeEach(async () => {
      await findBanner().vm.$emit('primary');
    });

    it('should send button click event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, CLICK_EVENT, {
        label: EVENT_LABEL,
      });
    });
  });
});
