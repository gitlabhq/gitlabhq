import { mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('DetailLayout', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = mount(DetailLayout, {
      propsData: props,
      slots,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findHeading = () => wrapper.find('[data-testid="page-heading"]');
  const findDescription = () => wrapper.find('[data-testid="page-heading-description"]');
  const findActions = () => wrapper.find('[data-testid="page-heading-actions"]');
  const findAlerts = () => wrapper.find('[data-testid="detail-layout-alerts"]');
  const findContainer = () => wrapper.find('[data-testid="detail-layout-container"]');
  const findSidebar = () => wrapper.find('[data-testid="detail-layout-sidebar"]');
  const findContent = () => wrapper.find('[data-testid="detail-layout-content"]');

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

    it('does not render container, content, or sidebar slot when loading', () => {
      createComponent(
        { heading: 'Test Heading', loading: true },
        { default: '<div>Content</div>', sidebar: '<div>Sidebar</div>' },
      );
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findContainer().exists()).toBe(false);
      expect(findContent().exists()).toBe(false);
      expect(findSidebar().exists()).toBe(false);
    });

    it('renders content and sidebar slot when not loading', () => {
      createComponent(
        { heading: 'Test Heading', loading: false },
        { default: '<div>Content</div>', sidebar: '<div>Sidebar</div>' },
      );
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findContainer().exists()).toBe(true);
      expect(findContent().text()).toContain('Content');
      expect(findSidebar().text()).toContain('Sidebar');
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

    describe('sidebar', () => {
      it('renders sidebar container when slot is provided', () => {
        createComponent({}, { sidebar: '<div>Content</div>' });
        expect(findSidebar().exists()).toBe(true);
      });

      it('does not render sidebar container when slots are not provided', () => {
        createComponent();
        expect(findSidebar().exists()).toBe(false);
      });
    });

    describe('default', () => {
      it('renders body when default slot is provided', () => {
        createComponent({}, { default: '<div>Content</div>' });
        expect(findContent().exists()).toBe(true);
      });
    });
  });
});
