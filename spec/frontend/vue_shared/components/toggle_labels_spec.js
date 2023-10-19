import { GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import ToggleLabels from '~/vue_shared/components/toggle_labels.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';

Vue.use(VueApollo);

describe('ToggleLabels', () => {
  let wrapper;

  const findToggle = () => wrapper.findComponent(GlToggle);

  const mockSetIsShowingLabelsResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      setIsShowingLabels: mockSetIsShowingLabelsResolver,
    },
  });

  const createComponent = () => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: isShowingLabelsQuery,
      data: {
        isShowingLabels: true,
      },
    });
    wrapper = shallowMountExtended(ToggleLabels, {
      apolloProvider: mockApollo,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('calls setIsShowingLabelsMutation on toggle', async () => {
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
});
