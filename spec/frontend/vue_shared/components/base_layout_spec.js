import { GlLoadingIcon, GlIntersectionObserver } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BaseLayout from '~/vue_shared/components/base_layout.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('BaseLayout', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = mountExtended(BaseLayout, {
      propsData: props,
      slots,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findHeading = () => wrapper.findByTestId('page-heading');
  const findDescription = () => wrapper.findByTestId('page-heading-description');
  const findActions = () => wrapper.findByTestId('page-heading-actions');
  const findAlerts = () => wrapper.findByTestId('base-layout-alerts');
  const findContent = () => wrapper.findByTestId('base-layout-content');
  const findStickyHeader = () => wrapper.findByTestId('base-layout-sticky-header');
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);

  describe('PageHeading', () => {
    describe('heading', () => {
      it('renders when heading prop is provided', () => {
        createComponent({ heading: 'Test Heading' });
        expect(findPageHeading().exists()).toBe(true);
        expect(findPageHeading().props('heading')).toBe('Test Heading');
      });

      it('renders when heading slot is provided', () => {
        createComponent({}, { heading: 'Custom Heading' });
        expect(findHeading().exists()).toBe(true);
      });

      it('renders actions inline with the heading', () => {
        createComponent({ heading: 'Test Heading' });
        expect(findPageHeading().props('inlineActions')).toBe(true);
      });
    });

    describe('description', () => {
      it('renders description when prop provided', () => {
        createComponent({ heading: 'Test Heading', description: 'Test description' });
        expect(findDescription().exists()).toBe(true);
      });

      it('renders description when slot provided', () => {
        createComponent({ heading: 'Test Heading' }, { description: 'Test description' });
        expect(findDescription().exists()).toBe(true);
      });

      it('does not render when no description prop or slot is provided', () => {
        createComponent({ heading: 'Test Heading' });
        expect(findDescription().exists()).toBe(false);
      });
    });

    describe('actions', () => {
      it('renders actions when slot provided', () => {
        createComponent({ heading: 'Test Heading' }, { actions: 'Test action' });
        expect(findActions().exists()).toBe(true);
      });

      it('does not render when no actions slot is provided', () => {
        createComponent({ heading: 'Test Heading' });
        expect(findActions().exists()).toBe(false);
      });
    });
  });

  describe('headingTag', () => {
    it('defaults to null', () => {
      createComponent();
      expect(findPageHeading().props('headingTag')).toBeNull();
    });

    it('passes headingTag prop to PageHeading', () => {
      createComponent({ headingTag: 'h2' });
      expect(findPageHeading().props('headingTag')).toBe('h2');
    });
  });

  describe('pageHeadingSrOnly', () => {
    it('does not apply gl-sr-only class by default', () => {
      createComponent({ heading: 'Test Heading' });
      expect(findPageHeading().classes()).not.toContain('gl-sr-only');
    });

    it('applies gl-sr-only class when pageHeadingSrOnly is true', () => {
      createComponent({ heading: 'Test Heading', pageHeadingSrOnly: true });
      expect(findPageHeading().classes()).toContain('gl-sr-only');
    });
  });

  describe('loading', () => {
    it('does not render loading icon by default', () => {
      createComponent({ heading: 'Test Heading' });
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders loading icon when loading prop is true', () => {
      createComponent({ heading: 'Test Heading', loading: true });
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render content slot when loading', () => {
      createComponent(
        { heading: 'Test Heading', loading: true },
        { default: '<div>Content</div>' },
      );
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findContent().text()).not.toContain('Content');
    });

    it('renders content slot when not loading', () => {
      createComponent(
        { heading: 'Test Heading', loading: false },
        { default: '<div>Content</div>' },
      );
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findContent().text()).toContain('Content');
    });
  });

  describe('slots', () => {
    describe('alerts', () => {
      it('renders alerts container when slot is provided', () => {
        createComponent({}, { alerts: '<div>Alerts slot content</div>' });
        expect(findAlerts().text()).toContain('Alerts slot content');
      });

      it('does not render when no alerts slot is provided', () => {
        createComponent({ heading: 'Test Heading' });
        expect(findAlerts().exists()).toBe(false);
      });
    });

    describe('default', () => {
      it('renders body when default slot is provided', () => {
        createComponent({}, { default: '<div>Content</div>' });
        expect(findContent().exists()).toBe(true);
      });
    });
  });

  describe('stickyHeader', () => {
    it('does not render the sticky header by default', () => {
      createComponent({ heading: 'Test Heading' });
      expect(findStickyHeader().exists()).toBe(false);
    });

    describe('sticky header fallback', () => {
      it('renders the sticky-header slot when provided', () => {
        createComponent(
          { heading: 'Test Heading' },
          { 'sticky-header': '<span>Custom sticky header</span>' },
        );
        expect(findStickyHeader().text()).toBe('Custom sticky header');
      });
    });

    describe('header height CSS variables', () => {
      const HEIGHT = 64;
      const LIVE_VAR = '--layout-sticky-header-height';
      const RESERVED_VAR = '--layout-sticky-header-reserved-height';
      const getVar = (name) => document.documentElement.style.getPropertyValue(name).trim();

      const mountWithStickyHeader = () => {
        createComponent({ heading: 'Test Heading' }, { 'sticky-header': '<span>Sticky</span>' });
        jest.spyOn(findStickyHeader().element, 'offsetHeight', 'get').mockReturnValue(HEIGHT);
      };

      afterEach(() => {
        document.documentElement.style.removeProperty(LIVE_VAR);
        document.documentElement.style.removeProperty(RESERVED_VAR);
      });

      it('sets the live and reserved header height when the header sticks', async () => {
        mountWithStickyHeader();

        findIntersectionObserver().vm.$emit('disappear');
        await waitForPromises();

        expect(getVar(LIVE_VAR)).toBe(`${HEIGHT}px`);
        expect(getVar(RESERVED_VAR)).toBe(`${HEIGHT}px`);
      });

      it('removes the live var but keeps the reserved var when the header hides', async () => {
        mountWithStickyHeader();

        findIntersectionObserver().vm.$emit('disappear');
        await waitForPromises();
        findIntersectionObserver().vm.$emit('appear');
        await waitForPromises();

        expect(getVar(LIVE_VAR)).toBe('');
        expect(getVar(RESERVED_VAR)).toBe(`${HEIGHT}px`);
      });
    });
  });
});
