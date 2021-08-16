import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { setCookie, parseBoolean } from '~/lib/utils/common_utils';
import TerraformNotification from '~/projects/terraform_notification/components/terraform_notification.vue';

jest.mock('~/lib/utils/common_utils');

const terraformImagePath = '/path/to/image';
const bannerDismissedKey = 'terraform_notification_dismissed';

describe('TerraformNotificationBanner', () => {
  let wrapper;

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
  });

  afterEach(() => {
    wrapper.destroy();
    parseBoolean.mockReturnValue(false);
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

    it('should remove the banner', () => {
      expect(findBanner().exists()).toBe(false);
    });
  });
});
