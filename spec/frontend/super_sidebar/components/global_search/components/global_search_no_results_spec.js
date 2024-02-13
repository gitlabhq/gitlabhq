import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalSearchNoResults from '~/super_sidebar/components/global_search/components/global_search_no_results.vue';

describe('GlobalSearchNoResults', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(GlobalSearchNoResults);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders message', () => {
    expect(wrapper.text()).toBe('No results found. Edit your search and try again.');
  });
});
