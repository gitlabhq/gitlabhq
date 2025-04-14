import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import setEnvironmentToDelete from '~/environments/graphql/mutations/set_environment_to_delete.mutation.graphql';
import DeleteComponent from '~/environments/components/environment_delete.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvedEnvironment } from './graphql/mock_data';

describe('External URL Component', () => {
  Vue.use(VueApollo);

  let mockApollo;
  let wrapper;

  const createWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(DeleteComponent, {
      ...options,
      propsData: {
        environment: resolvedEnvironment,
        ...props,
      },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    mockApollo = createMockApollo();
    createWrapper({ environment: resolvedEnvironment }, { apolloProvider: mockApollo });
  });

  it('should render a dropdown item to delete the environment', () => {
    expect(findDropdownItem().exists()).toBe(true);
    expect(findDropdownItem().props('item').text).toBe('Delete environment');
    expect(findDropdownItem().props('item').variant).toBe('danger');
  });

  it('emits requestDeleteEnvironment in the event hub when button is clicked', () => {
    jest.spyOn(mockApollo.defaultClient, 'mutate');
    findDropdownItem().vm.$emit('action');
    expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setEnvironmentToDelete,
      variables: { environment: resolvedEnvironment },
    });
  });
});
