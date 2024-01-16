import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NamespaceStorageApp from '~/usage_quotas/storage/components/namespace_storage_app.vue';
import StorageUsageStatistics from '~/usage_quotas/storage/components/storage_usage_statistics.vue';
import DependencyProxyUsage from '~/usage_quotas/storage/components/dependency_proxy_usage.vue';
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
  const findDependencyProxy = () => wrapper.findComponent(DependencyProxyUsage);
  const findBreakdownSubtitle = () => wrapper.findByTestId('breakdown-subtitle');

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
  beforeEach(() => {
    createComponent();
  });

  describe('Namespace usage overview', () => {
    describe('StorageUsageStatistics', () => {
      it('passes the correct props to StorageUsageStatistics', () => {
        expect(findStorageUsageStatistics().props()).toMatchObject({
          usedStorage: defaultProps.namespace.rootStorageStatistics.storageSize,
          loading: false,
        });
      });
    });
  });

  describe('Storage usage breakdown', () => {
    it('shows the namespace storage breakdown subtitle', () => {
      expect(findBreakdownSubtitle().text()).toBe('Storage usage breakdown');
    });

    describe('Dependency proxy usage', () => {
      it('shows the dependency proxy usage component', async () => {
        createComponent({
          provide: { userNamespace: false },
        });
        await waitForPromises();

        expect(findDependencyProxy().exists()).toBe(true);
      });

      it('does not display the dependency proxy for personal namespaces', () => {
        createComponent({
          provide: { userNamespace: true },
        });

        expect(findDependencyProxy().exists()).toBe(false);
      });
    });
  });
});
