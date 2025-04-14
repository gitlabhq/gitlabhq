import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import cancelAutoStopMutation from '~/environments/graphql/mutations/cancel_auto_stop.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import PinComponent from '~/environments/components/environment_pin.vue';

describe('Pin Component', () => {
  Vue.use(VueApollo);

  let mockApollo;
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(PinComponent, {
      ...options,
    });
  };

  const autoStopUrl = '/root/auto-stop-env-test/-/environments/38/cancel_auto_stop';

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    mockApollo = createMockApollo();
    factory({
      propsData: {
        autoStopUrl,
      },
      apolloProvider: mockApollo,
    });
  });

  it('should render the component with descriptive text', () => {
    expect(findDropdownItem().props('item').text).toBe('Prevent auto-stopping');
  });

  it('should emit onPinClick when clicked', () => {
    jest.spyOn(mockApollo.defaultClient, 'mutate');

    findDropdownItem().vm.$emit('action');

    expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
      mutation: cancelAutoStopMutation,
      variables: { autoStopUrl },
    });
  });
});
