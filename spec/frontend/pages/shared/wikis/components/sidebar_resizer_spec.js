import { mount } from '@vue/test-utils';
import SidebarResizer from '~/pages/shared/wikis/components/sidebar_resizer.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('SidebarResizer component', () => {
  useLocalStorageSpy();

  let wrapper;
  let matchMediaMock;
  let sidebar;
  let contentWrapper;

  beforeEach(() => {
    matchMediaMock = jest.fn().mockReturnValue({ matches: true });

    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: matchMediaMock,
    });
  });

  const createComponent = () => {
    document.body.innerHTML = `
      <div class="js-wiki-sidebar gl-hidden"></div>
      <div class="content-wrapper"></div>
    `;

    sidebar = document.querySelector('.js-wiki-sidebar');
    contentWrapper = document.querySelector('.content-wrapper');

    wrapper = mount(SidebarResizer, {
      attachTo: document.body,
      sidebar,
      contentWrapper,
    });
  };

  it('passes correct props to PanelResizer', () => {
    createComponent();

    expect(wrapper.findComponent(PanelResizer).props()).toMatchObject({
      startSize: expect.any(Number),
      side: 'left',
      minSize: expect.any(Number),
      maxSize: expect.any(Number),
      enabled: true,
    });
  });

  it('removes gl-hidden class from sidebar on mount', () => {
    createComponent();

    expect(sidebar.classList.contains('gl-hidden')).toBe(false);
  });

  it('updates sidebar width when PanelResizer emits update:size', async () => {
    createComponent();

    const initialWidth = sidebar.style.width;
    await wrapper.findComponent(PanelResizer).vm.$emit('update:size', 350);

    expect(sidebar.style.width).toBe('350px');
    expect(sidebar.style.width).not.toBe(initialWidth);
  });

  it('updates content-wrapper padding when sidebar width changes', async () => {
    createComponent();

    const initialPadding = contentWrapper.style.paddingRight;
    await wrapper.findComponent(PanelResizer).vm.$emit('update:size', 400);

    expect(contentWrapper.style.paddingRight).toBe('400px');
    expect(contentWrapper.style.paddingRight).not.toBe(initialPadding);
  });

  it('removes transition styles when PanelResizer emits resize-start', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('resize-start');

    expect(sidebar.style.transition).toBe('0s');
    expect(contentWrapper.style.transition).toBe('0s');
  });

  it('restores transition styles when PanelResizer emits resize-end', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('resize-end');

    expect(sidebar.style.transition).toBe('');
    expect(contentWrapper.style.transition).toBe('');
  });

  it('persists resize across multiple component renders', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('update:size', 400);

    expect(sidebar.style.width).toBe('400px');

    // Simulate component re-render or page refresh
    wrapper.destroy();
    createComponent();

    // Check if the width is still persisted
    expect(sidebar.style.width).toBe('400px');
  });

  it('disables resize and resets to original width when media query does not match', async () => {
    // First, let the media query match
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('update:size', 400);

    expect(sidebar.style.width).toBe('400px');

    // Now, make the media query not match
    matchMediaMock.mockImplementation(() => ({ matches: false }));

    // Simulate component re-render
    wrapper.destroy();
    createComponent();

    // Check if PanelResizer is not rendered
    expect(wrapper.findComponent(PanelResizer).exists()).toBe(false);

    // Check if the width is reset to original (empty string)
    expect(sidebar.style.width).toBe('');
  });
});
