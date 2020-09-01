import { shallowMount } from '@vue/test-utils';
import { GlNewDropdown, GlLink } from '@gitlab/ui';
import { createStore } from '~/integrations/edit/store';

import { integrationLevels, overrideDropdownDescriptions } from '~/integrations/edit/constants';
import OverrideDropdown from '~/integrations/edit/components/override_dropdown.vue';

describe('OverrideDropdown', () => {
  let wrapper;

  const defaultProps = {
    inheritFromId: 1,
    override: true,
  };

  const defaultAdminStateProps = {
    integrationLevel: 'group',
  };

  const createComponent = (props = {}, adminStateProps = {}) => {
    wrapper = shallowMount(OverrideDropdown, {
      propsData: { ...defaultProps, ...props },
      store: createStore({
        adminState: { ...defaultAdminStateProps, ...adminStateProps },
      }),
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

    describe('integrationLevel is "project"', () => {
      it('renders copy mentioning instance (as default fallback)', () => {
        createComponent(
          {},
          {
            integrationLevel: 'project',
          },
        );

        expect(wrapper.text()).toContain(overrideDropdownDescriptions[integrationLevels.INSTANCE]);
      });
    });

    describe('integrationLevel is "group"', () => {
      it('renders copy mentioning group', () => {
        createComponent(
          {},
          {
            integrationLevel: 'group',
          },
        );

        expect(wrapper.text()).toContain(overrideDropdownDescriptions[integrationLevels.GROUP]);
      });
    });

    describe('integrationLevel is "instance"', () => {
      it('renders copy mentioning instance', () => {
        createComponent(
          {},
          {
            integrationLevel: 'instance',
          },
        );

        expect(wrapper.text()).toContain(overrideDropdownDescriptions[integrationLevels.INSTANCE]);
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
