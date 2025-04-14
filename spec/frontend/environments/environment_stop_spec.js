import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import setEnvironmentToStopMutation from '~/environments/graphql/mutations/set_environment_to_stop.mutation.graphql';
import isEnvironmentStoppingQuery from '~/environments/graphql/queries/is_environment_stopping.query.graphql';
import StopComponent from '~/environments/components/environment_stop.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
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

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render a button to stop the environment', () => {
      expect(findButton().exists()).toBe(true);
      expect(wrapper.attributes('title')).toEqual('Stop environment');
    });
  });

  describe('graphql', () => {
    Vue.use(VueApollo);
    let mockApollo;
    const resolvers = {
      Query: {
        isEnvironmentStopping: () => true,
      },
    };

    const createWrapperWithApollo = () => {
      createWrapper({ environment: resolvedEnvironment }, { apolloProvider: mockApollo });
    };

    it('queries for environment stopping state', () => {
      mockApollo = createMockApollo([], resolvers);
      jest.spyOn(mockApollo.defaultClient, 'watchQuery');

      createWrapperWithApollo();

      expect(mockApollo.defaultClient.watchQuery).toHaveBeenCalledWith({
        query: isEnvironmentStoppingQuery,
        variables: { environment: resolvedEnvironment },
      });
    });

    it('sets the environment to stop on click', () => {
      mockApollo = createMockApollo();
      jest.spyOn(mockApollo.defaultClient, 'mutate');

      createWrapperWithApollo();

      findButton().vm.$emit('click');

      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: setEnvironmentToStopMutation,
        variables: { environment: resolvedEnvironment },
      });
    });

    describe('when the environment is currently stopping', () => {
      beforeEach(async () => {
        mockApollo = createMockApollo([], resolvers);

        createWrapperWithApollo();
        await waitForPromises();
      });

      it('should render a button with a loading icon and a correct title', () => {
        const button = findButton();

        expect(button.props('loading')).toBe(true);
        expect(wrapper.attributes('title')).toBe('Stopping environment');
      });
    });
  });

  describe('when the environment is in stopping state', () => {
    beforeEach(() => {
      createWrapper({ environment: { ...resolvedEnvironment, state: 'stopping' } });
    });

    it('should render a button with a loading icon and a correct title', () => {
      const button = findButton();

      expect(button.props('loading')).toBe(true);
      expect(wrapper.attributes('title')).toBe('Stopping environment');
    });
  });
});
