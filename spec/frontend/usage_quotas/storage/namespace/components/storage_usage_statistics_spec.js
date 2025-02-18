import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StorageUsageStatistics from '~/usage_quotas/storage/namespace/components/storage_usage_statistics.vue';
import StorageUsageOverviewCard from '~/usage_quotas/storage/namespace/components/storage_usage_overview_card.vue';
import { mockGetNamespaceStorageGraphQLResponse } from '../../mock_data';

const defaultProps = {
  usedStorage:
    mockGetNamespaceStorageGraphQLResponse.data.namespace.rootStorageStatistics.storageSize,
  loading: false,
};

describe('StorageUsageStatistics', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(StorageUsageStatistics, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findOverviewSubtitle = () => wrapper.findByTestId('overview-subtitle');
  const findStorageUsageOverviewCard = () => wrapper.findComponent(StorageUsageOverviewCard);

  beforeEach(() => {
    createComponent();
  });

  it('shows the namespace storage overview subtitle', () => {
    expect(findOverviewSubtitle().text()).toBe('Namespace overview');
  });

  describe('StorageStatisticsCard', () => {
    it('passes the correct props to StorageUsageOverviewCard', () => {
      expect(findStorageUsageOverviewCard().props()).toEqual({
        usedStorage: defaultProps.usedStorage,
        loading: false,
      });
    });
  });
});
