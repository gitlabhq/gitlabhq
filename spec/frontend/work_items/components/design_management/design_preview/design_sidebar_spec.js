import { GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DesignSidebar from '~/work_items/components/design_management/design_preview/design_sidebar.vue';
import DesignDescription from '~/work_items/components/design_management/design_preview/design_description.vue';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import mockDesign from './mock_design';

describe('DesignDescription', () => {
  let wrapper;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDisclosure = () => wrapper.findAllComponents(DesignDisclosure);
  const findDesignDescription = () => wrapper.findComponent(DesignDescription);

  function createComponent({ isLoading = false } = {}) {
    wrapper = shallowMountExtended(DesignSidebar, {
      propsData: {
        design: mockDesign,
        isLoading,
        isOpen: true,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders disclosure', () => {
    expect(findDisclosure().exists()).toBe(true);
  });

  it('renders design description', () => {
    expect(findDesignDescription().exists()).toBe(true);
    expect(findDesignDescription().props()).toMatchObject({
      design: mockDesign,
    });
  });

  it('renders empty state', () => {
    expect(findEmptyState().exists()).toBe(true);
    expect(findSkeletonLoader().exists()).toBe(false);
  });

  it('renders loading state when loading', () => {
    createComponent({ isLoading: true });
    expect(findEmptyState().exists()).toBe(false);
    expect(findSkeletonLoader().exists()).toBe(true);
  });
});
