import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EditEnvironment from '~/environments/components/edit_environment.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import getEnvironment from '~/environments/graphql/queries/environment.query.graphql';
import updateEnvironment from '~/environments/graphql/mutations/update_environment.mutation.graphql';
import { __ } from '~/locale';
import createMockApollo from '../__helpers__/mock_apollo_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

const newExternalUrl = 'https://google.ca';
const environment = {
  id: '1',
  name: 'foo',
  externalUrl: 'https://foo.example.com',
  clusterAgent: null,
};
const resolvedEnvironment = { project: { id: '1', environment } };
const environmentUpdate = {
  environment: { id: '1', path: 'path/to/environment', clusterAgentId: null },
  errors: [],
};
const environmentUpdateError = {
  environment: null,
  errors: [{ message: 'uh oh!' }],
};

const provide = {
  projectEnvironmentsPath: '/projects/environments',
  updateEnvironmentPath: '/projects/environments/1',
  protectedEnvironmentSettingsPath: '/projects/1/settings/ci_cd',
  projectPath: '/path/to/project',
};

describe('~/environments/components/edit.vue', () => {
  let wrapper;
  let mock;

  const createMockApolloProvider = (mutationResult) => {
    Vue.use(VueApollo);

    const mocks = [
      [getEnvironment, jest.fn().mockResolvedValue({ data: resolvedEnvironment })],
      [
        updateEnvironment,
        jest.fn().mockResolvedValue({ data: { environmentUpdate: mutationResult } }),
      ],
    ];

    return createMockApollo(mocks);
  };

  const createWrapper = () => {
    wrapper = mountExtended(EditEnvironment, {
      propsData: { environment: { id: '1', name: 'foo', external_url: 'https://foo.example.com' } },
      provide,
    });
  };

  const createWrapperWithApollo = async ({ mutationResult = environmentUpdate } = {}) => {
    wrapper = mountExtended(EditEnvironment, {
      propsData: { environment: {} },
      provide: {
        ...provide,
        glFeatures: {
          environmentSettingsToGraphql: true,
        },
      },
      apolloProvider: createMockApolloProvider(mutationResult),
    });

    await waitForPromises();
  };

  const findNameInput = () => wrapper.findByLabelText(__('Name'));
  const findExternalUrlInput = () => wrapper.findByLabelText(__('External URL'));
  const findForm = () => wrapper.findByRole('form', { name: __('Edit environment') });

  const showsLoading = () => wrapper.findComponent(GlLoadingIcon).exists();

  const submitForm = async () => {
    await findExternalUrlInput().setValue(newExternalUrl);
    await findForm().trigger('submit');
  };

  describe('default', () => {
    beforeEach(async () => {
      await createWrapper();
    });

    it('sets the title to Edit environment', () => {
      const header = wrapper.findByRole('heading', { name: __('Edit environment') });
      expect(header.exists()).toBe(true);
    });

    it('renders a disabled "Name" field', () => {
      const nameInput = findNameInput();

      expect(nameInput.attributes().disabled).toBe('disabled');
      expect(nameInput.element.value).toBe(environment.name);
    });

    it('renders an "External URL" field', () => {
      const urlInput = findExternalUrlInput();

      expect(urlInput.element.value).toBe(environment.externalUrl);
    });
  });

  describe('when environmentSettingsToGraphql feature is enabled', () => {
    describe('when mounted', () => {
      beforeEach(() => {
        createWrapperWithApollo();
      });
      it('renders loading icon when environment query is loading', () => {
        expect(showsLoading()).toBe(true);
      });
    });

    describe('when mutation successful', () => {
      beforeEach(async () => {
        await createWrapperWithApollo();
      });

      it('shows loader after form is submitted', async () => {
        expect(showsLoading()).toBe(false);

        await submitForm();

        expect(showsLoading()).toBe(true);
      });

      it('submits the updated environment on submit', async () => {
        await submitForm();
        await waitForPromises();

        expect(visitUrl).toHaveBeenCalledWith(environmentUpdate.environment.path);
      });
    });

    describe('when mutation failed', () => {
      beforeEach(async () => {
        await createWrapperWithApollo({
          mutationResult: environmentUpdateError,
        });
      });

      it('shows errors on error', async () => {
        await submitForm();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({ message: 'uh oh!' });
        expect(showsLoading()).toBe(false);
      });
    });
  });

  describe('when environmentSettingsToGraphql feature is disabled', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      createWrapper();
    });

    afterEach(() => {
      mock.restore();
    });

    it('shows loader after form is submitted', async () => {
      expect(showsLoading()).toBe(false);

      mock
        .onPut(provide.updateEnvironmentPath, {
          external_url: newExternalUrl,
          id: environment.id,
        })
        .reply(...[HTTP_STATUS_OK, { path: '/test' }]);

      await submitForm();

      expect(showsLoading()).toBe(true);
    });

    it('submits the updated environment on submit', async () => {
      mock
        .onPut(provide.updateEnvironmentPath, {
          external_url: newExternalUrl,
          id: environment.id,
        })
        .reply(...[HTTP_STATUS_OK, { path: '/test' }]);

      await submitForm();
      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith('/test');
    });

    it('shows errors on error', async () => {
      mock
        .onPut(provide.updateEnvironmentPath, {
          external_url: newExternalUrl,
          id: environment.id,
        })
        .reply(...[HTTP_STATUS_BAD_REQUEST, { message: ['uh oh!'] }]);

      await submitForm();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: 'uh oh!' });
      expect(showsLoading()).toBe(false);
    });
  });
});
