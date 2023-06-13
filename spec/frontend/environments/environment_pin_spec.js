import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import cancelAutoStopMutation from '~/environments/graphql/mutations/cancel_auto_stop.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import PinComponent from '~/environments/components/environment_pin.vue';
import eventHub from '~/environments/event_hub';

describe('Pin Component', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(PinComponent, {
      ...options,
    });
  };

  const autoStopUrl = '/root/auto-stop-env-test/-/environments/38/cancel_auto_stop';

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  describe('without graphql', () => {
    beforeEach(() => {
      factory({
        propsData: {
          autoStopUrl,
        },
      });
    });

    it('should render the component with descriptive text', () => {
      expect(findDropdownItem().props('item').text).toBe('Prevent auto-stopping');
    });

    it('should emit onPinClick when clicked', () => {
      const eventHubSpy = jest.spyOn(eventHub, '$emit');

      findDropdownItem().vm.$emit('action');

      expect(eventHubSpy).toHaveBeenCalledWith('cancelAutoStop', autoStopUrl);
    });
  });

  describe('with graphql', () => {
    Vue.use(VueApollo);
    let mockApollo;

    beforeEach(() => {
      mockApollo = createMockApollo();
      factory({
        propsData: {
          autoStopUrl,
          graphql: true,
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
});
