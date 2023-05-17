import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import setEnvironmentToStopMutation from '~/environments/graphql/mutations/set_environment_to_stop.mutation.graphql';
import isEnvironmentStoppingQuery from '~/environments/graphql/queries/is_environment_stopping.query.graphql';
import StopComponent from '~/environments/components/environment_stop.vue';
import eventHub from '~/environments/event_hub';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvedEnvironment } from './graphql/mock_data';

describe('Stop Component', () => {
  let wrapper;

  const createWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(StopComponent, {
      propsData: {
        environment: {},
        ...props,
      },
      ...options,
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  describe('eventHub', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render a button to stop the environment', () => {
      expect(findButton().exists()).toBe(true);
      expect(wrapper.attributes('title')).toEqual('Stop environment');
    });

    it('emits requestStopEnvironment in the event hub when button is clicked', () => {
      jest.spyOn(eventHub, '$emit');
      findButton().vm.$emit('click');
      expect(eventHub.$emit).toHaveBeenCalledWith('requestStopEnvironment', wrapper.vm.environment);
    });
  });

  describe('graphql', () => {
    Vue.use(VueApollo);
    let mockApollo;

    beforeEach(() => {
      mockApollo = createMockApollo();
      mockApollo.clients.defaultClient.writeQuery({
        query: isEnvironmentStoppingQuery,
        variables: { environment: resolvedEnvironment },
        data: { isEnvironmentStopping: true },
      });

      createWrapper(
        { graphql: true, environment: resolvedEnvironment },
        { apolloProvider: mockApollo },
      );
    });

    it('should render a button to stop the environment', () => {
      expect(findButton().exists()).toBe(true);
      expect(wrapper.attributes('title')).toEqual('Stop environment');
    });

    it('sets the environment to stop on click', () => {
      jest.spyOn(mockApollo.defaultClient, 'mutate');
      findButton().vm.$emit('click');
      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: setEnvironmentToStopMutation,
        variables: { environment: resolvedEnvironment },
      });
    });

    it('should show a loading icon if the environment is currently stopping', () => {
      expect(findButton().props('loading')).toBe(true);
    });
  });
});
