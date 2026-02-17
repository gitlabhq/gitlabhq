import { mount } from '@vue/test-utils';
import SidebarResizer from '~/wikis/components/sidebar_resizer.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('SidebarResizer component', () => {
  useLocalStorageSpy();

  let wrapper;
  let sidebarContainer;
  let sidebar;

  const createComponent = () => {
    document.body.innerHTML = `
      <div class="sidebar-container">
        <div class="wiki-sidebar"></div>
      </div>
    `;

    sidebarContainer = document.querySelector('.sidebar-container');
    sidebar = document.querySelector('.wiki-sidebar');

    wrapper = mount(SidebarResizer, {
      attachTo: document.body,
      sidebar: sidebarContainer,
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

    expect(sidebarContainer.classList.contains('gl-hidden')).toBe(false);
  });

  it('updates sidebar width when PanelResizer emits update:size', async () => {
    createComponent();

    const initialWidth = sidebarContainer.style.width;
    await wrapper.findComponent(PanelResizer).vm.$emit('update:size', 350);

    expect(sidebarContainer.style.width).toBe('350px');
    expect(sidebarContainer.style.width).not.toBe(initialWidth);
  });

  it('removes transition styles when PanelResizer emits resize-start', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('resize-start');

    expect(sidebar.classList).not.toContain('transition-enabled');
  });

  it('restores transition styles when PanelResizer emits resize-end', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('resize-end');

    expect(sidebar.classList).toContain('transition-enabled');
  });

  it('persists resize across multiple component renders', async () => {
    createComponent();

    await wrapper.findComponent(PanelResizer).vm.$emit('update:size', 400);

    expect(sidebarContainer.style.width).toBe('400px');

    // Simulate component re-render or page refresh
    wrapper.destroy();
    createComponent();

    // Check if the width is still persisted
    expect(sidebarContainer.style.width).toBe('400px');
  });
});
