import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RollbackComponent from '~/environments/components/environment_rollback.vue';
import setEnvironmentToRollback from '~/environments/graphql/mutations/set_environment_to_rollback.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';

describe('Rollback Component', () => {
  let wrapper;

  const retryUrl = 'https://gitlab.com/retry';

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  it('Should render Re-deploy label when isLastDeployment is true', () => {
    wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        isLastDeployment: true,
        environment: {},
      },
    });

    expect(findDropdownItem().props('item').text).toBe('Re-deploy to environment');
  });

  it('Should render Rollback label when isLastDeployment is false', () => {
    wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        isLastDeployment: false,
        environment: {},
      },
    });

    expect(findDropdownItem().props('item').text).toBe('Rollback environment');
  });

  it('should trigger a graphql mutation', () => {
    Vue.use(VueApollo);

    const apolloProvider = createMockApollo();
    jest.spyOn(apolloProvider.defaultClient, 'mutate');
    const environment = {
      name: 'test',
    };

    wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        environment,
      },
      apolloProvider,
    });

    findDropdownItem().vm.$emit('action');

    expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setEnvironmentToRollback,
      variables: { environment: { ...environment, isLastDeployment: true, retryUrl } },
    });
  });
});
