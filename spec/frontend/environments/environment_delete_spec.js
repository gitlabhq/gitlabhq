import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import setEnvironmentToDelete from '~/environments/graphql/mutations/set_environment_to_delete.mutation.graphql';
import DeleteComponent from '~/environments/components/environment_delete.vue';
import eventHub from '~/environments/event_hub';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvedEnvironment } from './graphql/mock_data';

describe('External URL Component', () => {
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

  describe('event hub', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render a dropdown item to delete the environment', () => {
      expect(findDropdownItem().exists()).toBe(true);
      expect(findDropdownItem().props('item').text).toBe('Delete environment');
      expect(findDropdownItem().props('item').extraAttrs.variant).toBe('danger');
    });

    it('emits requestDeleteEnvironment in the event hub when button is clicked', () => {
      jest.spyOn(eventHub, '$emit');
      findDropdownItem().vm.$emit('action');
      expect(eventHub.$emit).toHaveBeenCalledWith('requestDeleteEnvironment', resolvedEnvironment);
    });
  });

  describe('graphql', () => {
    Vue.use(VueApollo);
    let mockApollo;

    beforeEach(() => {
      mockApollo = createMockApollo();
      createWrapper(
        { graphql: true, environment: resolvedEnvironment },
        { apolloProvider: mockApollo },
      );
    });

    it('should render a dropdown item to delete the environment', () => {
      expect(findDropdownItem().exists()).toBe(true);
      expect(findDropdownItem().props('item').text).toBe('Delete environment');
      expect(findDropdownItem().props('item').extraAttrs.variant).toBe('danger');
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
});
