import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FeatureLibraryRecommended from '~/super_sidebar/components/feature_library/feature_library_recommended.vue';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';

const items = [
  { id: 'repository', title: 'Repository', description: 'Browse and manage code', icon: 'code' },
  { id: 'pipelines', title: 'Pipelines', description: 'Automate your workflows', icon: 'pipeline' },
];

describe('FeatureLibraryRecommended', () => {
  let wrapper;

  const createWrapper = ({ pinnedIds = [] } = {}) => {
    wrapper = shallowMountExtended(FeatureLibraryRecommended, {
      propsData: { items, pinnedIds },
    });
  };

  const findHeading = () => wrapper.findByTestId('feature-library-recommended-heading');
  const findItems = () => wrapper.findAllComponents(FeatureLibraryItem);

  it('renders the Recommended heading', () => {
    createWrapper();
    expect(findHeading().text()).toBe('Recommended');
  });

  it('renders one item per recommended entry, each with a solid background', () => {
    createWrapper();
    expect(findItems()).toHaveLength(items.length);
    expect(findItems().wrappers.every((w) => w.props('solidBackground'))).toBe(true);
  });

  it('marks items whose id is in pinnedIds as pinned', () => {
    createWrapper({ pinnedIds: ['pipelines'] });
    const repository = findItems().at(0);
    const pipelines = findItems().at(1);
    expect(repository.props('pinned')).toBe(false);
    expect(pipelines.props('pinned')).toBe(true);
  });

  it('re-emits pin-toggle from items', () => {
    createWrapper();
    findItems().at(0).vm.$emit('pin-toggle', 'repository', true, 'Repository');
    expect(wrapper.emitted('pin-toggle')).toEqual([['repository', true, 'Repository']]);
  });
});
