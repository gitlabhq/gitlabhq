import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';

import OverrideDropdown from '~/integrations/edit/components/override_dropdown.vue';
import { integrationLevels, overrideDropdownDescriptions } from '~/integrations/constants';
import { useIntegrationForm } from '~/integrations/edit/store';

Vue.use(PiniaVuePlugin);

describe('OverrideDropdown', () => {
  let wrapper;

  const defaultProps = {
    inheritFromId: 1,
    override: true,
  };

  const defaultDefaultStateProps = {
    integrationLevel: 'group',
  };

  const createComponent = (props = {}, defaultStateProps = {}) => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      defaultState: { ...defaultDefaultStateProps, ...defaultStateProps },
    });

    wrapper = shallowMount(OverrideDropdown, {
      propsData: { ...defaultProps, ...props },
      pinia,
    });
  };

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('template', () => {
    describe('override prop is true', () => {
      it('renders GlToggle as disabled', () => {
        createComponent();

        expect(findGlCollapsibleListbox().props('toggleText')).toBe('Use custom settings');
      });
    });

    describe('override prop is false', () => {
      it('renders GlToggle as disabled', () => {
        createComponent({ override: false });

        expect(findGlCollapsibleListbox().props('toggleText')).toBe('Use default settings');
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

        expect(findGlLink().text()).toBe('Learn more.');
        expect(findGlLink().attributes('href')).toBe('/docs');
      });
    });
  });
});
