import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PromoPageLink from '~/vue_shared/components/promo_page_link/promo_page_link.vue';
import { PROMO_URL } from '~/constants';
import { joinPaths } from '~/lib/utils/url_utility';

let wrapper;

const createComponent = (propsData = {}, slots = {}) => {
  wrapper = shallowMount(PromoPageLink, {
    propsData,
    slots,
    stubs: {
      GlLink: true,
    },
  });
};

const findGlLink = () => wrapper.findComponent(GlLink);

describe('HelpPageLink', () => {
  it('renders a link', () => {
    const path = 'pricing';
    createComponent({ path });

    const link = findGlLink();
    const expectedHref = joinPaths(PROMO_URL, path);
    expect(link.attributes().href).toBe(expectedHref);
  });

  it('with a leading slash and anchor', () => {
    const path = '/pricing#anchor';
    createComponent({ path });

    const link = findGlLink();
    const expectedHref = joinPaths(PROMO_URL, path);
    expect(link.attributes().href).toBe(expectedHref);
  });

  it('renders slot content', () => {
    const path = 'pricing';
    const slotContent = 'slot content';
    createComponent({ path }, { default: slotContent });

    const link = findGlLink();
    expect(link.text()).toBe(slotContent);
  });
});
