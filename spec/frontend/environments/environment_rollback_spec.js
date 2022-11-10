import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RollbackComponent from '~/environments/components/environment_rollback.vue';
import eventHub from '~/environments/event_hub';
import setEnvironmentToRollback from '~/environments/graphql/mutations/set_environment_to_rollback.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';

describe('Rollback Component', () => {
  const retryUrl = 'https://gitlab.com/retry';

  it('Should render Re-deploy label when isLastDeployment is true', () => {
    const wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        isLastDeployment: true,
        environment: {},
      },
    });

    expect(wrapper.text()).toBe('Re-deploy to environment');
  });

  it('Should render Rollback label when isLastDeployment is false', () => {
    const wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        isLastDeployment: false,
        environment: {},
      },
    });

    expect(wrapper.text()).toBe('Rollback environment');
  });

  it('should emit a "rollback" event on button click', () => {
    const eventHubSpy = jest.spyOn(eventHub, '$emit');
    const wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        environment: {
          name: 'test',
        },
      },
    });
    const button = wrapper.findComponent(GlDropdownItem);

    button.vm.$emit('click');

    expect(eventHubSpy).toHaveBeenCalledWith('requestRollbackEnvironment', {
      retryUrl,
      isLastDeployment: true,
      name: 'test',
    });
  });

  it('should trigger a graphql mutation when graphql is enabled', () => {
    Vue.use(VueApollo);

    const apolloProvider = createMockApollo();
    jest.spyOn(apolloProvider.defaultClient, 'mutate');
    const environment = {
      name: 'test',
    };
    const wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        graphql: true,
        environment,
      },
      apolloProvider,
    });
    const button = wrapper.findComponent(GlDropdownItem);
    button.vm.$emit('click');

    expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setEnvironmentToRollback,
      variables: { environment: { ...environment, isLastDeployment: true, retryUrl } },
    });
  });
});
