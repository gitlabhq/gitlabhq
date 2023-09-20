import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EditEnvironment from '~/environments/components/edit_environment.vue';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import getEnvironment from '~/environments/graphql/queries/environment.query.graphql';
import updateEnvironment from '~/environments/graphql/mutations/update_environment.mutation.graphql';
import { __ } from '~/locale';
import createMockApollo from '../__helpers__/mock_apollo_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

const environment = {
  id: '1',
  name: 'foo',
  externalUrl: 'https://foo.example.com',
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
    wrapper = mountExtended(EditEnvironment, {
      propsData: { environment: {} },
      provide: {
        ...provide,
      },
      apolloProvider: createMockApolloProvider(mutationHandler),
    });

    await waitForPromises();
  };

  const findNameInput = () => wrapper.findByLabelText(__('Name'));
  const findExternalUrlInput = () => wrapper.findByLabelText(__('External URL'));
  const findForm = () => wrapper.findByRole('form', { name: __('Edit environment') });

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

      const header = wrapper.findByRole('heading', { name: __('Edit environment') });
      expect(header.exists()).toBe(true);
    });

    it('renders a disabled "Name" field', async () => {
      await createWrapperWithApollo();

      const nameInput = findNameInput();
      expect(nameInput.attributes().disabled).toBe('disabled');
      expect(nameInput.element.value).toBe(environment.name);
    });

    it('renders an "External URL" field', async () => {
      await createWrapperWithApollo();

      const urlInput = findExternalUrlInput();
      expect(urlInput.element.value).toBe(environment.externalUrl);
    });
  });

  describe('on submit', () => {
    it('performs the updateEnvironment apollo mutation', async () => {
      await createWrapperWithApollo();
      await findForm().trigger('submit');

      expect(updateEnvironmentSuccess).toHaveBeenCalled();
    });

    describe('when mutation successful', () => {
      beforeEach(async () => {
        await createWrapperWithApollo();
      });

      it('shows loader after form is submitted', async () => {
        expect(showsLoading()).toBe(false);

        await findForm().trigger('submit');

        expect(showsLoading()).toBe(true);
      });

      it('submits the updated environment on submit', async () => {
        await findForm().trigger('submit');
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
        await findForm().trigger('submit');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({ message: 'uh oh!' });
        expect(showsLoading()).toBe(false);
      });
    });
  });
});
