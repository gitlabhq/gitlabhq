import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceStorageApp from '~/usage_quotas/storage/components/namespace_storage_app.vue';
import StorageUsageStatistics from '~/usage_quotas/storage/components/storage_usage_statistics.vue';
import { defaultNamespaceProvideValues } from '../mock_data';

const defaultProps = {
  namespaceLoadingError: false,
  projectsLoadingError: false,
  isNamespaceStorageStatisticsLoading: false,
  // hardcoding object until we move test_fixtures from ee/ to here
  namespace: {
    rootStorageStatistics: {
      storageSize: 1234,
    },
  },
};

describe('NamespaceStorageApp', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findStorageUsageStatistics = () => wrapper.findComponent(StorageUsageStatistics);

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    wrapper = shallowMountExtended(NamespaceStorageApp, {
      provide: {
        ...defaultNamespaceProvideValues,
        ...provide,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('Namespace usage overview', () => {
    describe('StorageUsageStatistics', () => {
      beforeEach(() => {
        createComponent();
      });

      it('passes the correct props to StorageUsageStatistics', () => {
        expect(findStorageUsageStatistics().props()).toMatchObject({
          usedStorage: defaultProps.namespace.rootStorageStatistics.storageSize,
          loading: false,
        });
      });
    });
  });
});
