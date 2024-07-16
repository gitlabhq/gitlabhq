import { nextTick } from 'vue';
import { GlSkeletonLoader, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DesignToolbar from '~/work_items/components/design_management/design_preview/design_toolbar.vue';
import CloseButton from '~/work_items/components/design_management/design_preview/close_button.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import mockDesign from './mock_design';

describe('DesignToolbar', () => {
  let wrapper;
  const workItemTitle = 'Test title';

  function createComponent({ isLoading = false, design = mockDesign } = {}) {
    wrapper = shallowMountExtended(DesignToolbar, {
      propsData: {
        workItemTitle,
        isLoading,
        design,
        isSidebarOpen: true,
        designFilename: design.filename,
      },
    });
  }

  it('renders skeleton loader when loading', () => {
    createComponent({ isLoading: true });

    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  it('does mot render skeleton loader when loaded', () => {
    createComponent();

    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
  });

  it('renders issue title and design filename', () => {
    createComponent();

    expect(wrapper.find('h2').text()).toContain(workItemTitle);
    expect(wrapper.find('h2').text()).toContain(mockDesign.filename);
  });

  it('renders download button with correct link', () => {
    createComponent();

    expect(wrapper.findComponent(GlButton).attributes('href')).toBe(mockDesign.image);
  });

  it('renders close button', () => {
    createComponent();

    expect(wrapper.findComponent(CloseButton).exists()).toBe(true);
  });

  it('renders imported badge when design is imported', () => {
    createComponent();

    expect(wrapper.findComponent(ImportedBadge).exists()).toBe(true);
  });

  it('does not render imported badge when design is not imported', () => {
    createComponent({ design: { ...mockDesign, imported: false } });

    expect(wrapper.findComponent(ImportedBadge).exists()).toBe(false);
  });

  it('emits toggle-sidebar event when clicking on toggle sidebar button', async () => {
    createComponent();

    wrapper.findByTestId('toggle-design-sidebar').vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('toggle-sidebar')).toHaveLength(1);
  });
});
