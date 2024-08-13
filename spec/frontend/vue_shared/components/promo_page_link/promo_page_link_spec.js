import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PromoPageLink from '~/vue_shared/components/promo_page_link/promo_page_link.vue';
import { PROMO_URL } from '~/constants';
import { joinPaths } from '~/lib/utils/url_utility';

let wrapper;

const createComponent = (props = {}, slots = {}) => {
  wrapper = shallowMount(PromoPageLink, {
    propsData: {
      ...props,
    },
    slots,
    stubs: {
      GlLink: true,
    },
  });
};

const findGlLink = () => wrapper.findComponent(GlLink);

describe('HelpPageLink', () => {
  it('renders a link', () => {
    const href = 'pricing';
    createComponent({ href });

    const link = findGlLink();
    const expectedHref = joinPaths(PROMO_URL, href);
    expect(link.attributes().href).toBe(expectedHref);
  });

  it('with a leading slash and anchor', () => {
    const href = '/pricing#anchor';
    createComponent({ href });

    const link = findGlLink();
    const expectedHref = joinPaths(PROMO_URL, href);
    expect(link.attributes().href).toBe(expectedHref);
  });

  it('renders slot content', () => {
    const href = 'pricing';
    const slotContent = 'slot content';
    createComponent({ href }, { default: slotContent });

    const link = findGlLink();
    expect(link.text()).toBe(slotContent);
  });
});
