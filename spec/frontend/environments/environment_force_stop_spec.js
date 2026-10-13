import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import setEnvironmentToStopMutation from '~/environments/graphql/mutations/set_environment_to_stop.mutation.graphql';
import ForceStopComponent from '~/environments/components/environment_force_stop.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvedEnvironment } from './graphql/mock_data';

describe('Environment force stop component', () => {
  Vue.use(VueApollo);

  let mockApollo;
  let wrapper;

  const environment = { ...resolvedEnvironment, state: 'stopping' };

  const createWrapper = () => {
    wrapper = shallowMount(ForceStopComponent, {
      apolloProvider: mockApollo,
      propsData: { environment },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    mockApollo = createMockApollo();
    createWrapper();
  });

  it('renders a danger dropdown item to force stop the environment', () => {
    expect(findDropdownItem().props('item')).toEqual({
      text: 'Force stop environment',
      variant: 'danger',
    });
  });

  it('sets the environment to stop when the item is actioned', () => {
    jest.spyOn(mockApollo.defaultClient, 'mutate');

    findDropdownItem().vm.$emit('action');

    expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setEnvironmentToStopMutation,
      variables: { environment },
    });
  });
});
