import { mount } from '@vue/test-utils';
import IndexLayout from '~/vue_shared/components/index_layout.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('IndexLayout', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = mount(IndexLayout, {
      propsData: props,
      slots,
    });
  };

  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findHeading = () => wrapper.find('[data-testid="page-heading"]');
  const findDescription = () => wrapper.find('[data-testid="page-heading-description"]');
  const findAlerts = () => wrapper.find('[data-testid="index-layout-alerts"]');
  const findContent = () => wrapper.find('[data-testid="index-layout-content"]');

  describe('PageHeading', () => {
    describe('heading', () => {
      it('renders when heading prop is provided', () => {
        createComponent({ heading: 'Test Heading' });
        expect(findPageHeading().exists()).toBe(true);
        expect(findPageHeading().props('heading')).toBe('Test Heading');
        expect(findPageHeading().classes()).toContain('!gl-my-0');
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
  });

  describe('slots', () => {
    describe('alerts', () => {
      it('renders alerts container when slot is provided', () => {
        createComponent({}, { alerts: '<div>Content</div>' });
        expect(findAlerts().exists()).toBe(true);
      });

      it('does not render alerts container when slots are not provided', () => {
        createComponent();
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
});
