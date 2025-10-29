import { mount } from '@vue/test-utils';
import SidebarResizer from '~/wikis/components/sidebar_resizer.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('SidebarResizer component', () => {
  useLocalStorageSpy();

  let wrapper;
  let sidebar;

  const createComponent = () => {
    document.body.innerHTML = `
      <div class="sidebar-container"></div>
    `;

    sidebar = document.querySelector('.sidebar-container');

    wrapper = mount(SidebarResizer, {
      attachTo: document.body,
      sidebar,
    });
  };

  it('passes correct props to PanelResizer', () => {
    createComponent();

    expect(wrapper.findComponent(PanelResizer).props()).toMatchObject({
      startSize: expect.any(Number),
      side: 'right',
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

  it('removes transition styles when PanelResizer emits resize-start', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('resize-start');

    expect(sidebar.style.transition).toBe('0s');
  });

  it('restores transition styles when PanelResizer emits resize-end', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('resize-end');

    expect(sidebar.style.transition).toBe('');
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
});
