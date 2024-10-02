import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EditEnvironment from '~/environments/components/edit_environment.vue';
import EnvironmentForm from '~/environments/components/environment_form.vue';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import getEnvironment from '~/environments/graphql/queries/environment.query.graphql';
import updateEnvironment from '~/environments/graphql/mutations/update_environment.mutation.graphql';
import createMockApollo from '../__helpers__/mock_apollo_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

const environment = {
  id: '1',
  name: 'foo',
  externalUrl: 'https://foo.example.com',
  description: 'this is description',
  clusterAgent: null,
  kubernetesNamespace: null,
  fluxResourcePath: null,
};
const resolvedEnvironment = { project: { id: '1', environment } };
const environmentUpdateSuccess = {
  environment: { id: '1', path: 'path/to/environment', clusterAgentId: null },
  errors: [],
};
const environmentUpdateError = {
  environment: null,
  errors: [{ message: 'uh oh!' }],
};

const provide = {
  projectEnvironmentsPath: '/projects/environments',
  protectedEnvironmentSettingsPath: '/projects/1/settings/ci_cd',
  projectPath: '/path/to/project',
  environmentName: 'foo',
};

describe('~/environments/components/edit.vue', () => {
  let wrapper;

  const getEnvironmentQuery = jest.fn().mockResolvedValue({ data: resolvedEnvironment });

  const updateEnvironmentSuccess = jest
    .fn()
    .mockResolvedValue({ data: { environmentUpdate: environmentUpdateSuccess } });
  const updateEnvironmentFail = jest
    .fn()
    .mockResolvedValue({ data: { environmentUpdate: environmentUpdateError } });

  const createMockApolloProvider = (mutationHandler) => {
    Vue.use(VueApollo);

    const mocks = [
      [getEnvironment, getEnvironmentQuery],
      [updateEnvironment, mutationHandler],
    ];

    return createMockApollo(mocks);
  };

  const createWrapperWithApollo = async ({ mutationHandler = updateEnvironmentSuccess } = {}) => {
    wrapper = shallowMountExtended(EditEnvironment, {
      propsData: { environment: {} },
      provide: {
        ...provide,
      },
      apolloProvider: createMockApolloProvider(mutationHandler),
    });

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(EnvironmentForm);

  const showsLoading = () => wrapper.findComponent(GlLoadingIcon).exists();

  describe('default', () => {
    it('performs the environment apollo query', () => {
      createWrapperWithApollo();
      expect(getEnvironmentQuery).toHaveBeenCalled();
    });

    it('renders loading icon when environment query is loading', () => {
      createWrapperWithApollo();
      expect(showsLoading()).toBe(true);
    });

    it('sets the title to Edit environment', async () => {
      await createWrapperWithApollo();
      expect(findForm().props('title')).toBe('Edit environment');
    });
  });

  describe('on submit', () => {
    it('performs the updateEnvironment apollo mutation', async () => {
      await createWrapperWithApollo();
      findForm().vm.$emit('submit');

      expect(updateEnvironmentSuccess).toHaveBeenCalled();
    });

    describe('when mutation successful', () => {
      beforeEach(async () => {
        await createWrapperWithApollo();
      });

      it('shows loader after form is submitted', async () => {
        expect(findForm().props('loading')).toBe(false);

        findForm().vm.$emit('submit');
        await nextTick();

        expect(findForm().props('loading')).toBe(true);
      });

      it('submits the updated environment on submit', async () => {
        findForm().vm.$emit('submit');
        await waitForPromises();

        expect(visitUrl).toHaveBeenCalledWith(environmentUpdateSuccess.environment.path);
      });
    });

    describe('when mutation failed', () => {
      beforeEach(async () => {
        await createWrapperWithApollo({
          mutationHandler: updateEnvironmentFail,
        });
      });

      it('shows errors on error', async () => {
        findForm().vm.$emit('submit');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({ message: 'uh oh!' });
        expect(findForm().props('loading')).toBe(false);
      });
    });
  });
});
