import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { setCookie, parseBoolean } from '~/lib/utils/common_utils';
import TerraformNotification from '~/projects/terraform_notification/components/terraform_notification.vue';

jest.mock('~/lib/utils/common_utils');

const bannerDissmisedKey = 'terraform_notification_dismissed_for_project_1';

describe('TerraformNotificationBanner', () => {
  let wrapper;

  const propsData = {
    projectId: 1,
  };
  const findBanner = () => wrapper.findComponent(GlBanner);

  beforeEach(() => {
    wrapper = shallowMount(TerraformNotification, {
      propsData,
      stubs: { GlBanner },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    parseBoolean.mockReturnValue(false);
  });

  describe('when the dismiss cookie is set', () => {
    beforeEach(() => {
      parseBoolean.mockReturnValue(true);
      wrapper = shallowMount(TerraformNotification, {
        propsData,
      });
    });

    it('should not render the banner', () => {
      expect(findBanner().exists()).toBe(false);
    });
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

    it('should set the cookie with the bannerDissmisedKey', () => {
      expect(setCookie).toHaveBeenCalledWith(bannerDissmisedKey, true);
    });

    it('should remove the banner', () => {
      expect(findBanner().exists()).toBe(false);
    });
  });
});
