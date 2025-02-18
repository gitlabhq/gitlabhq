import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContainerRegistryUsage from '~/usage_quotas/storage/namespace/components/container_registry_usage.vue';
import StorageTypeWarning from '~/usage_quotas/storage/components/storage_type_warning.vue';

describe('Container registry usage component', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const defaultProps = {
    containerRegistrySize: 512,
    containerRegistrySizeIsEstimated: false,
  };

  const findTotalSizeSection = () => wrapper.findByTestId('total-size-section');
  const findWarningIcon = () => wrapper.findComponent(StorageTypeWarning);

  const createComponent = (props) => {
    wrapper = shallowMountExtended(ContainerRegistryUsage, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays the total size section when prop is provided', () => {
    expect(findTotalSizeSection().props('value')).toBe(defaultProps.containerRegistrySize);
  });

  describe('estimated value indication', () => {
    it('hides warning icon', () => {
      createComponent({
        containerRegistrySizeIsEstimated: false,
      });
      expect(findWarningIcon().exists()).toBe(false);
    });

    it('displays warning icon', () => {
      createComponent({
        containerRegistrySizeIsEstimated: true,
      });
      expect(findWarningIcon().exists()).toBe(true);
    });
  });
});
