import { shallowMount } from '@vue/test-utils';
import GlobalCatalog from '~/ci/catalog/global_catalog.vue';
import CiCatalogHome from '~/ci/catalog/components/ci_catalog_home.vue';

describe('GlobalCatalog', () => {
  let wrapper;

  const findHomeComponent = () => wrapper.findComponent(CiCatalogHome);

  beforeEach(() => {
    wrapper = shallowMount(GlobalCatalog);
  });

  it('renders the catalog home component', () => {
    expect(findHomeComponent().exists()).toBe(true);
  });
});
