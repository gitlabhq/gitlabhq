import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StorageUsageStatistics from '~/usage_quotas/storage/components/storage_usage_statistics.vue';
import StorageUsageOverviewCard from '~/usage_quotas/storage/components/storage_usage_overview_card.vue';

const defaultProps = {
  // hardcoding value until we move test_fixtures from ee/ to here
  usedStorage: 1234,
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
