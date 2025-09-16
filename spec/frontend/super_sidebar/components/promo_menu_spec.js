import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PromoMenu from '~/super_sidebar/components/promo_menu.vue';

describe('PromoMenu', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findExploreButton = () => wrapper.findByTestId('explore-button');
  const findMenu = () => wrapper.findByTestId('menu');

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
    });
  };

  describe('template', () => {
    it('renders only explore when not in SaaS mode', () => {
      createComponent();

      expect(findExploreButton().props('href')).toBe('/explore');
      expect(findExploreButton().text()).toBe('Explore');

      expect(findDropdown().exists()).toBe(false);
      expect(findMenu().exists()).toBe(false);
    });

    it('renders all items when in SaaS mode', () => {
      createComponent({}, { isSaas: true });

      expect(findExploreButton().exists()).toBe(false);
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
  });
});
