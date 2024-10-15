import { shallowMount, Wrapper } from '@vue/test-utils'; // eslint-disable-line no-unused-vars
import { GlLink } from '@gitlab/ui';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

/** @type { Wrapper } */
let wrapper;

const createComponent = (props = {}, slots = {}) => {
  wrapper = shallowMount(HelpPageLink, {
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
    const href = 'user/storage_usage_quotas';
    createComponent({ href });

    const link = findGlLink();
    const expectedHref = helpPagePath(href, { anchor: null });
    expect(link.attributes().href).toBe(expectedHref);
  });

  it('adds the anchor', () => {
    const href = 'user/storage_usage_quotas';
    const anchor = 'namespace-storage-limit';
    createComponent({ href, anchor });

    const link = findGlLink();
    const expectedHref = helpPagePath(href, { anchor });
    expect(link.attributes().href).toBe(expectedHref);
  });

  it('renders slot content', () => {
    const href = 'user/storage_usage_quotas';
    const slotContent = 'slot content';
    createComponent({ href }, { default: slotContent });

    const link = findGlLink();
    expect(link.text()).toBe(slotContent);
  });
});
