import { shallowMount } from '@vue/test-utils';
import { GlToggle } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import SetContainerScanningForRegistry from '~/security_configuration/graphql/set_container_scanning_for_registry.graphql';
import ContinuousContainerRegistryScan from '~/security_configuration/components/continous_container_registry_scan.vue';
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

describe('ContinuousContainerRegistryScan', () => {
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

    wrapper = shallowMount(ContinuousContainerRegistryScan, {
      propsData: {
        feature: {
          available: true,
          configured: true,
        },
      },
      provide: {
        glFeatures: {
          containerScanningForRegistry: true,
        },
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

  it('renders the correct title', () => {
    expect(wrapper.text()).toContain('Continuous Container Scanning');
  });

  it('renders the toggle component with correct values', () => {
    expect(findToggle().exists()).toBe(true);
    expect(findToggle().props('value')).toBe(defaultProvide.containerScanningForRegistryEnabled);
  });

  it('should disable toggle when feature is not configured', () => {
    createComponent({
      propsData: {
        feature: {
          available: true,
          configured: false,
        },
      },
    });
    expect(findToggle().props('disabled')).toBe(true);
  });

  it.each([true, false])(
    'calls mutation on toggle change with correct payload',
    async (enabled) => {
      createComponent({ enabled });

      findToggle().vm.$emit('change', enabled);

      expect(requestHandlers.setCVSMutationHandler).toHaveBeenCalledWith({
        input: {
          projectPath: 'project/full/path',
          enable: enabled,
        },
      });

      await waitForPromises();

      expect(findToggle().props('value')).toBe(enabled);
    },
  );

  describe('when feature flag is disabled', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          glFeatures: {
            containerScanningForRegistry: false,
          },
          ...defaultProvide,
        },
      });
    });

    it('should not render toggle', () => {
      expect(findToggle().exists()).toBe(false);
    });
  });
});
