import { shallowMount } from '@vue/test-utils';
import { GlNewDropdown, GlLink } from '@gitlab/ui';

import OverrideDropdown from '~/integrations/edit/components/override_dropdown.vue';

describe('OverrideDropdown', () => {
  let wrapper;

  const defaultProps = {
    inheritFromId: 1,
    override: true,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(OverrideDropdown, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findGlLink = () => wrapper.find(GlLink);
  const findGlNewDropdown = () => wrapper.find(GlNewDropdown);

  describe('template', () => {
    describe('override prop is true', () => {
      it('renders GlToggle as disabled', () => {
        createComponent();

        expect(findGlNewDropdown().props('text')).toBe('Use custom settings');
      });
    });

    describe('override prop is false', () => {
      it('renders GlToggle as disabled', () => {
        createComponent({ override: false });

        expect(findGlNewDropdown().props('text')).toBe('Use default settings');
      });
    });

    describe('learnMorePath is present', () => {
      it('renders GlLink with correct link', () => {
        createComponent({
          learnMorePath: '/docs',
        });

        expect(findGlLink().text()).toBe('Learn more');
        expect(findGlLink().attributes('href')).toBe('/docs');
      });
    });
  });
});
