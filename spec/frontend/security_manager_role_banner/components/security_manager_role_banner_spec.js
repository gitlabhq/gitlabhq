import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SecurityManagerRoleBanner from '~/security_manager_role_banner/components/security_manager_role_banner.vue';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

describe('SecurityManagerRoleBanner', () => {
  let wrapper;
  let dismissSpy;

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    dismissSpy = jest.fn();
    wrapper = shallowMount(SecurityManagerRoleBanner, {
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: dismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const findBanner = () => wrapper.findComponent(GlBanner);

  describe('when the callout should be shown', () => {
    beforeEach(() => {
      createComponent();
    });

    it('wires the security_manager_role feature name into UserCalloutDismisser', () => {
      expect(wrapper.findComponent(UserCalloutDismisser).props('featureName')).toBe(
        'security_manager_role',
      );
    });

    it('renders the banner with the expected title, button, and help link', () => {
      expect(findBanner().props()).toMatchObject({
        title: 'New Security Manager role now available',
        buttonText: 'Learn more',
        buttonLink: helpPagePath('user/permissions'),
      });
    });

    it('calls the dismiss callback when the banner is closed', () => {
      findBanner().vm.$emit('close');

      expect(dismissSpy).toHaveBeenCalled();
    });
  });

  describe('when the callout should not be shown', () => {
    it('does not render the banner', () => {
      createComponent({ shouldShowCallout: false });

      expect(findBanner().exists()).toBe(false);
    });
  });
});
