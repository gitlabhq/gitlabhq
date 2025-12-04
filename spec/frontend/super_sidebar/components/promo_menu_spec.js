import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PromoMenu from '~/super_sidebar/components/promo_menu.vue';

describe('PromoMenu', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findMenu = () => wrapper.findByTestId('menu');
  const findSigninButton = () => wrapper.findByTestId('topbar-signin-button');
  const findSignupButton = () => wrapper.findByTestId('topbar-signup-button');

  const createComponent = (props = {}, provideOverrides = {}) => {
    wrapper = shallowMountExtended(PromoMenu, {
      propsData: {
        pricingUrl: '/pricing',
        ...props,
      },
      provide: {
        isSaas: false,
        ...provideOverrides,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  describe('template', () => {
    it('renders dropdown with only explore item when not in SaaS mode', () => {
      createComponent();

      expect(findDropdown().exists()).toBe(true);
      expect(findDropdown().props('items')).toEqual([{ href: '/explore', text: 'Explore' }]);
      expect(findMenu().exists()).toBe(true);
    });

    it('renders all items when in SaaS mode', () => {
      createComponent({}, { isSaas: true });

      expect(findMenu().exists()).toBe(true);

      expect(wrapper.vm.visibleItems).toEqual([
        // eslint-disable-next-line no-restricted-syntax
        { href: 'https://about.gitlab.com/why-gitlab', text: 'Why GitLab' },
        { href: '/pricing', text: 'Pricing' },
        { href: '/explore', text: 'Explore' },
      ]);

      expect(findDropdown().props('items')).toEqual([
        // eslint-disable-next-line no-restricted-syntax
        { href: 'https://about.gitlab.com/why-gitlab', text: 'Why GitLab' },
        { href: '/pricing', text: 'Pricing' },
        {
          extraAttrs: { dataMenuOnly: true },
          // eslint-disable-next-line no-restricted-syntax
          href: 'https://about.gitlab.com/sales',
          text: 'Contact Sales',
        },
        { href: '/explore', text: 'Explore' },
      ]);
    });

    it('renders pricingUrl', () => {
      createComponent({ pricingUrl: '/custom-pricing-url' }, { isSaas: true });

      expect(findDropdown().props('items')).toContainEqual(
        expect.objectContaining({
          href: '/custom-pricing-url',
          text: 'Pricing',
        }),
      );
    });

    it('renders buttons in SaaS mode', () => {
      createComponent(
        {
          allowSignUp: true,
          signInVisible: true,
          sidebarData: {
            new_user_registration_path: '/register',
            sign_in_path: '/sign-in',
          },
        },
        { isSaas: true },
      );

      expect(findSigninButton().props('href')).toBe('/sign-in');
      expect(findSignupButton().props('href')).toBe('/register');
      expect(findSignupButton().text()).toBe('Get free trial');
    });

    it('renders buttons in self-managed mode', () => {
      createComponent({
        allowSignUp: true,
        signInVisible: true,
        sidebarData: {
          new_user_registration_path: '/register',
          sign_in_path: '/sign-in',
        },
      });

      expect(findSigninButton().props('href')).toBe('/sign-in');
      expect(findSignupButton().props('href')).toBe('/register');
      expect(findSignupButton().text()).toBe('Register');
    });

    it('does not render register button when signup is disabled', () => {
      createComponent({
        allowSignUp: false,
        signInVisible: true,
        sidebarData: {
          sign_in_path: '/sign-in',
        },
      });

      expect(findSignupButton().exists()).toBe(false);
      expect(findSigninButton().exists()).toBe(true);
    });

    it('does not render auth buttons section when both signup and signin are disabled', () => {
      createComponent({
        allowSignUp: false,
        signInVisible: false,
      });

      expect(findSignupButton().exists()).toBe(false);
      expect(findSigninButton().exists()).toBe(false);
    });
  });
});
