import { GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import ToggleLabels from '~/vue_shared/components/toggle_labels.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';

Vue.use(VueApollo);

describe('ToggleLabels', () => {
  let wrapper;

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const mockSetIsShowingLabelsResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      setIsShowingLabels: mockSetIsShowingLabelsResolver,
    },
  });

  const createComponent = (propsData = {}) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: isShowingLabelsQuery,
      data: {
        isShowingLabels: true,
      },
    });
    wrapper = shallowMountExtended(ToggleLabels, {
      apolloProvider: mockApollo,
      propsData,
    });
  };

  it('calls setIsShowingLabelsMutation on toggle', async () => {
    createComponent();

    expect(findToggle().props('value')).toBe(true);
    findToggle().vm.$emit('change', false);

    await waitForPromises();

    expect(mockSetIsShowingLabelsResolver).toHaveBeenCalledWith(
      {},
      {
        isShowingLabels: false,
      },
      expect.anything(),
      expect.anything(),
    );
  });

  it('uses prop as storage key', () => {
    createComponent({
      storageKey: 'test-storage-key',
    });

    expect(findLocalStorageSync().props('storageKey')).toBe('test-storage-key');
  });
});
