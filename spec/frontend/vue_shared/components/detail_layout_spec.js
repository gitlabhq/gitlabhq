import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';

describe('DetailLayout', () => {
  let wrapper;

  useFakeRequestAnimationFrame();

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

  describe('sidebar space', () => {
    const SPACE_VAR = '--detail-layout-sidebar-space';
    let scrollContainer;
    let sidebarTopSpy;

    const getSpace = () => findSidebar().element.style.getPropertyValue(SPACE_VAR);

    const setSidebarTop = (top) => sidebarTopSpy.mockReturnValue({ top });

    const spyOnSidebar = (sidebarTop) => {
      sidebarTopSpy = jest.spyOn(findSidebar().element, 'getBoundingClientRect');
      setSidebarTop(sidebarTop);
    };

    const mountInScrollContainer = ({ containerTop = 0, sidebarTop = 0, loading = false } = {}) => {
      scrollContainer = document.createElement('div');
      scrollContainer.className = 'panel-content-inner';
      document.body.appendChild(scrollContainer);

      createComponent(
        { loading },
        { default: '<div>Content</div>', sidebar: '<div>Sidebar</div>' },
      );
      scrollContainer.appendChild(wrapper.element);

      jest.spyOn(scrollContainer, 'getBoundingClientRect').mockReturnValue({ top: containerTop });
      if (!loading) spyOnSidebar(sidebarTop);
    };

    const flush = async () => {
      await nextTick();
    };

    const scroll = async () => {
      scrollContainer.dispatchEvent(new Event('scroll'));
      await flush();
    };

    afterEach(() => {
      scrollContainer?.remove();
    });

    it('sets the space to the distance from the container top to the sidebar top', async () => {
      mountInScrollContainer({ containerTop: 0, sidebarTop: 120 });
      await flush();

      expect(getSpace()).toBe('120px');
    });

    it('clamps a negative distance to zero', async () => {
      mountInScrollContainer({ containerTop: 200, sidebarTop: 100 });
      await flush();

      expect(getSpace()).toBe('0px');
    });

    it('re-measures live on scroll so the height tracks the sidebar position', async () => {
      mountInScrollContainer({ containerTop: 0, sidebarTop: 120 });
      await flush();
      expect(getSpace()).toBe('120px');

      // The sidebar has scrolled up and pinned below the sticky header.
      setSidebarTop(32);
      await scroll();

      expect(getSpace()).toBe('32px');
    });

    it('re-measures on resize', async () => {
      mountInScrollContainer({ containerTop: 0, sidebarTop: 120 });
      await flush();

      setSidebarTop(80);
      window.dispatchEvent(new Event('resize'));
      await flush();

      expect(getSpace()).toBe('80px');
    });

    it('wires up the scroll sync once the sidebar renders after loading completes', async () => {
      mountInScrollContainer({ containerTop: 0, loading: true });
      await flush();
      // Sidebar is not rendered while loading, so nothing is measured yet.
      expect(findSidebar().exists()).toBe(false);

      // Loading completes: the sidebar renders and the sync must wire up against it.
      wrapper.setProps({ loading: false });
      await flush();
      spyOnSidebar(120);

      // A scroll now drives a measurement, proving the listener was attached.
      await scroll();

      expect(getSpace()).toBe('120px');
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
