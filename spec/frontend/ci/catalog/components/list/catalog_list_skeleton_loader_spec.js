import { shallowMount } from '@vue/test-utils';
import CatalogListSkeletonLoader from '~/ci/catalog/components/list/catalog_list_skeleton_loader.vue';

describe('CatalogListSkeletonLoader', () => {
  let wrapper;

  const findSkeletonLoader = () => wrapper.findComponent(CatalogListSkeletonLoader);

  const createComponent = () => {
    wrapper = shallowMount(CatalogListSkeletonLoader, {});
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders skeleton item', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });
});
