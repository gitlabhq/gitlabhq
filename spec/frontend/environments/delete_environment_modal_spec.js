import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { s__, sprintf } from '~/locale';
import DeleteEnvironmentModal from '~/environments/components/delete_environment_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvedEnvironment } from './graphql/mock_data';

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
        s__(
          `Environments|Deleting the '%{environmentName}' environment cannot be undone. Do you want to delete it anyway?`,
        ),
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

    expect(deleteResolver).toHaveBeenCalledWith(
      expect.anything(),
      { environment: resolvedEnvironment },
      expect.anything(),
      expect.anything(),
    );
  });
});
