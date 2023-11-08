import { GlLoadingIcon } from '@gitlab/ui';
import ProvisionedObservabilityContainer from '~/observability/components/provisioned_observability_container.vue';
import ObservabilityContainer from '~/observability/components/observability_container.vue';
import ObservabilityEmptyState from '~/observability/components/observability_empty_state.vue';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

jest.mock('~/alert');

describe('ProvisionedObservabilityContainer', () => {
  let wrapper;
  let mockClient;

  const mockClientReady = async () => {
    await wrapper
      .findComponent(ObservabilityContainer)
      .vm.$emit('observability-client-ready', mockClient);
  };

  const mockClientReadyAndWait = async () => {
    await wrapper
      .findComponent(ObservabilityContainer)
      .vm.$emit('observability-client-ready', mockClient);
    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(ObservabilityEmptyState);
  const findSlotComponent = () => wrapper.findComponent({ name: 'MockComponent' });

  const props = {
    apiConfig: {
      oauthUrl: 'https://example.com/oauth',
      tracingUrl: 'https://example.com/tracing',
      servicesUrl: 'https://example.com/services',
      provisioningUrl: 'https://example.com/provisioning',
      operationsUrl: 'https://example.com/operations',
      metricsUrl: 'https://example.com/metrics',
    },
  };

  beforeEach(() => {
    mockClient = {
      isObservabilityEnabled: jest.fn().mockResolvedValue(true),
      enableObservability: jest.fn().mockResolvedValue(true),
    };
    wrapper = shallowMountExtended(ProvisionedObservabilityContainer, {
      propsData: props,
      slots: {
        default: {
          render(h) {
            h(`<div>mockedComponent</div>`);
          },
          name: 'MockComponent',
        },
      },
    });
  });

  it('renders the observability-container', () => {
    const observabilityContainer = wrapper.findComponent(ObservabilityContainer);
    expect(observabilityContainer.exists()).toBe(true);
    expect(observabilityContainer.props('apiConfig')).toStrictEqual(props.apiConfig);
  });

  describe('when the client is ready', () => {
    it('renders the loading indicator while checking if observability is enabled', async () => {
      await mockClientReady();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
      expect(findSlotComponent().exists()).toBe(false);
      expect(mockClient.isObservabilityEnabled).toHaveBeenCalledTimes(1);
    });

    describe('if observability is enabled', () => {
      beforeEach(async () => {
        mockClient.isObservabilityEnabled.mockResolvedValue(true);
        await mockClientReadyAndWait();
      });

      it('renders the content slot', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(false);
        expect(findSlotComponent().exists()).toBe(true);
      });
    });

    describe('if observability is not enabled', () => {
      beforeEach(async () => {
        mockClient.isObservabilityEnabled.mockResolvedValue(false);
        await mockClientReadyAndWait();
      });

      it('renders the empty state', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
        expect(findSlotComponent().exists()).toBe(false);
      });

      describe('when empty-state emits enable-observability', () => {
        it('shows the loading icon', async () => {
          await findEmptyState().vm.$emit('enable-observability');

          expect(findLoadingIcon().exists()).toBe(true);
        });

        it('enable observability', async () => {
          await findEmptyState().vm.$emit('enable-observability');

          expect(mockClient.enableObservability).toHaveBeenCalledTimes(1);
        });

        it('shows the content slot', async () => {
          await findEmptyState().vm.$emit('enable-observability');
          await waitForPromises();

          expect(findLoadingIcon().exists()).toBe(false);
          expect(findEmptyState().exists()).toBe(false);
          expect(findSlotComponent().exists()).toBe(true);
        });
      });
    });
  });

  describe('error handling', () => {
    it('shows an alert if checking if observability is enabled fails', async () => {
      mockClient.isObservabilityEnabled.mockRejectedValue(new Error('error'));

      await mockClientReadyAndWait();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findSlotComponent().exists()).toBe(false);
      expect(createAlert).toHaveBeenLastCalledWith({
        message: 'Error: Failed to load page. Try reloading the page.',
      });
    });

    it('shows an alert when checking if observability is enabled fails', async () => {
      mockClient.isObservabilityEnabled.mockResolvedValue(false);
      mockClient.enableObservability.mockRejectedValue(new Error('error'));

      await mockClientReadyAndWait();

      await findEmptyState().vm.$emit('enable-observability');
      await waitForPromises();

      expect(createAlert).toHaveBeenLastCalledWith({
        message: 'Error: Failed to enable GitLab Observability. Please retry later.',
      });
    });
  });
});
