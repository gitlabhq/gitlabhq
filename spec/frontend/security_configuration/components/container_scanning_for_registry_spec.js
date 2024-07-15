import { shallowMount } from '@vue/test-utils';
import { GlToggle } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import SetContainerScanningForRegistry from '~/security_configuration/graphql/set_container_scanning_for_registry.graphql';
import ContainerScanningForRegistry from '~/security_configuration/components/container_scanning_for_registry.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

const getSetCVSMockResponse = (enabled = true) => ({
  data: {
    setContainerScanningForRegistry: {
      containerScanningForRegistryEnabled: enabled,
      errors: [],
    },
  },
});

const defaultProvide = {
  containerScanningForRegistryEnabled: true,
  projectFullPath: 'project/full/path',
};

describe('ContainerScanningForRegistry', () => {
  let wrapper;
  let apolloProvider;
  let requestHandlers;

  const createComponent = (options = {}) => {
    requestHandlers = {
      setCVSMutationHandler: jest.fn().mockResolvedValue(getSetCVSMockResponse(options.enabled)),
    };

    apolloProvider = createMockApollo([
      [SetContainerScanningForRegistry, requestHandlers.setCVSMutationHandler],
    ]);

    wrapper = shallowMount(ContainerScanningForRegistry, {
      propsData: {
        feature: {
          available: true,
          configured: true,
        },
      },
      provide: {
        ...defaultProvide,
      },
      apolloProvider,
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const findToggle = () => wrapper.findComponent(GlToggle);

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('renders the toggle component with correct values', () => {
    expect(findToggle().exists()).toBe(true);
    expect(findToggle().props('value')).toBe(defaultProvide.containerScanningForRegistryEnabled);
  });

  it('should allow toggle when feature is not configured', () => {
    createComponent({
      propsData: {
        feature: {
          available: true,
          configured: false,
        },
      },
    });
    expect(findToggle().props('disabled')).toBe(false);
  });

  it.each([true, false])(
    'calls mutation on toggle change with correct payload when %s',
    async (enabled) => {
      createComponent({ enabled });

      findToggle().vm.$emit('change', enabled);

      expect(requestHandlers.setCVSMutationHandler).toHaveBeenCalledWith({
        input: {
          namespacePath: 'project/full/path',
          enable: enabled,
        },
      });

      await waitForPromises();

      expect(findToggle().props('value')).toBe(enabled);
    },
  );

  it('emits the overrideStatus event with toggle value', async () => {
    const enabled = true;
    createComponent({ enabled });

    findToggle().vm.$emit('change', enabled);

    expect(requestHandlers.setCVSMutationHandler).toHaveBeenCalledWith({
      input: {
        namespacePath: 'project/full/path',
        enable: enabled,
      },
    });

    await waitForPromises();

    expect(wrapper.emitted().overrideStatus).toHaveLength(1);
    expect(wrapper.emitted().overrideStatus[0][0]).toBe(true);
  });
});
