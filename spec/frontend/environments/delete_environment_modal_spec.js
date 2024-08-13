import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import DeleteEnvironmentModal from '~/environments/components/delete_environment_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { resolvedEnvironment } from './graphql/mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('~/environments/components/delete_environment_modal.vue', () => {
  let mockApollo;
  let deleteResolver;
  let wrapper;

  const createComponent = ({ props = {}, apolloProvider } = {}) => {
    wrapper = shallowMount(DeleteEnvironmentModal, {
      propsData: {
        graphql: true,
        environment: resolvedEnvironment,
        ...props,
      },
      apolloProvider,
    });
  };

  beforeEach(() => {
    deleteResolver = jest.fn();
    mockApollo = createMockApollo([], {
      Mutation: { deleteEnvironment: deleteResolver },
    });
  });

  it('should confirm the environment to delete', () => {
    createComponent({ apolloProvider: mockApollo });

    expect(wrapper.text()).toBe(
      sprintf(
        `Deleting the '%{environmentName}' environment cannot be undone. Do you want to delete it anyway?`,

        {
          environmentName: resolvedEnvironment.name,
        },
      ),
    );
  });

  it('should send the delete mutation on primary', async () => {
    createComponent({ apolloProvider: mockApollo });

    wrapper.findComponent(GlModal).vm.$emit('primary');

    await nextTick();

    expect(createAlert).not.toHaveBeenCalled();

    expect(deleteResolver).toHaveBeenCalledWith(
      expect.anything(),
      { environment: resolvedEnvironment },
      expect.anything(),
      expect.anything(),
    );
  });

  it('should alert a message on error', async () => {
    createComponent({ apolloProvider: mockApollo });

    deleteResolver.mockRejectedValue();

    wrapper.findComponent(GlModal).vm.$emit('primary');

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        message:
          'An error occurred while deleting the environment. Check if the environment stopped; if not, stop it and try again.',

        captureError: true,
      }),
    );

    expect(deleteResolver).toHaveBeenCalledWith(
      expect.anything(),
      { environment: resolvedEnvironment },
      expect.anything(),
      expect.anything(),
    );
  });
});
