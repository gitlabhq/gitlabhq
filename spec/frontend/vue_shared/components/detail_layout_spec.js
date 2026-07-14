import { mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';

describe('DetailLayout', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = mount(DetailLayout, {
      propsData: props,
      slots,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findContainer = () => wrapper.find('[data-testid="detail-layout-container"]');
  const findSidebar = () => wrapper.find('[data-testid="detail-layout-sidebar"]');
  const findContent = () => wrapper.find('[data-testid="detail-layout-content"]');

  describe('loading', () => {
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

  describe('showSidebar', () => {
    it('applies the has-sidebar class by default when sidebar slot is provided', () => {
      createComponent({}, { sidebar: '<div>Sidebar</div>' });
      expect(findContainer().classes()).toContain('gl-detail-layout-container-has-sidebar');
    });

    it('does not apply the has-sidebar class when showSidebar is false, but keeps the sidebar in the DOM', () => {
      createComponent({ showSidebar: false }, { sidebar: '<div>Sidebar</div>' });
      expect(findContainer().classes()).not.toContain('gl-detail-layout-container-has-sidebar');
      expect(findSidebar().exists()).toBe(true);
    });

    it('makes the sidebar wrapper display:contents when showSidebar is false so it reserves no grid space', () => {
      createComponent({ showSidebar: false }, { sidebar: '<div>Sidebar</div>' });
      expect(findSidebar().classes()).toContain('gl-contents');
    });

    it('does not make the sidebar wrapper display:contents by default', () => {
      createComponent({}, { sidebar: '<div>Sidebar</div>' });
      expect(findSidebar().classes()).not.toContain('gl-contents');
    });
  });
});
