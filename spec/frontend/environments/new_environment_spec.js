import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewEnvironment from '~/environments/components/new_environment.vue';
import createEnvironment from '~/environments/graphql/mutations/create_environment.mutation.graphql';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import createMockApollo from '../__helpers__/mock_apollo_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

const newName = 'test';
const newExternalUrl = 'https://google.ca';

const provide = {
  projectEnvironmentsPath: '/projects/environments',
  projectPath: '/path/to/project',
};

const environmentCreate = { environment: { id: '1', path: 'path/to/environment' }, errors: [] };
const environmentCreateError = {
  environment: null,
  errors: [{ message: 'uh oh!' }],
};

describe('~/environments/components/new.vue', () => {
  let wrapper;
  let mock;

  const createMockApolloProvider = (mutationResult) => {
    Vue.use(VueApollo);

    return createMockApollo([
      [
        createEnvironment,
        jest.fn().mockResolvedValue({ data: { environmentCreate: mutationResult } }),
      ],
    ]);
  };

  const createWrapperWithApollo = async (mutationResult = environmentCreate) => {
    wrapper = mountExtended(NewEnvironment, {
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

  const createWrapperWithAxios = () => {
    wrapper = mountExtended(NewEnvironment, {
      provide: {
        ...provide,
        glFeatures: {
          environmentSettingsToGraphql: false,
        },
      },
    });
  };

  const findNameInput = () => wrapper.findByLabelText(__('Name'));
  const findExternalUrlInput = () => wrapper.findByLabelText(__('External URL'));
  const findForm = () => wrapper.findByRole('form', { name: __('New environment') });
  const showsLoading = () => wrapper.findComponent(GlLoadingIcon).exists();

  const submitForm = async () => {
    await findNameInput().setValue('test');
    await findExternalUrlInput().setValue('https://google.ca');

    await findForm().trigger('submit');
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapperWithAxios();
    });

    it('sets the title to New environment', () => {
      const header = wrapper.findByRole('heading', { name: 'New environment' });
      expect(header.exists()).toBe(true);
    });

    it.each`
      input                           | value
      ${() => findNameInput()}        | ${'test'}
      ${() => findExternalUrlInput()} | ${'https://example.org'}
    `('changes the value of the input to $value', ({ input, value }) => {
      input().setValue(value);

      expect(input().element.value).toBe(value);
    });
  });

  describe('when environmentSettingsToGraphql feature is enabled', () => {
    describe('when mutation successful', () => {
      beforeEach(() => {
        createWrapperWithApollo();
      });

      it('shows loader after form is submitted', async () => {
        expect(showsLoading()).toBe(false);

        await submitForm();

        expect(showsLoading()).toBe(true);
      });

      it('submits the new environment on submit', async () => {
        submitForm();
        await waitForPromises();

        expect(visitUrl).toHaveBeenCalledWith('path/to/environment');
      });
    });

    describe('when failed', () => {
      beforeEach(async () => {
        createWrapperWithApollo(environmentCreateError);
        submitForm();
        await waitForPromises();
      });

      it('shows errors on error', () => {
        expect(createAlert).toHaveBeenCalledWith({ message: 'uh oh!' });
        expect(showsLoading()).toBe(false);
      });
    });
  });

  describe('when environmentSettingsToGraphql feature is disabled', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      createWrapperWithAxios();
    });

    afterEach(() => {
      mock.restore();
    });

    it('shows loader after form is submitted', async () => {
      expect(showsLoading()).toBe(false);

      mock
        .onPost(provide.projectEnvironmentsPath, {
          name: newName,
          external_url: newExternalUrl,
        })
        .reply(HTTP_STATUS_OK, { path: '/test' });

      await submitForm();

      expect(showsLoading()).toBe(true);
    });

    it('submits the new environment on submit', async () => {
      mock
        .onPost(provide.projectEnvironmentsPath, {
          name: newName,
          external_url: newExternalUrl,
        })
        .reply(HTTP_STATUS_OK, { path: '/test' });

      await submitForm();
      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith('/test');
    });

    it('shows errors on error', async () => {
      mock
        .onPost(provide.projectEnvironmentsPath, {
          name: newName,
          external_url: newExternalUrl,
        })
        .reply(HTTP_STATUS_BAD_REQUEST, { message: ['name taken'] });

      await submitForm();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: 'name taken' });
      expect(showsLoading()).toBe(false);
    });
  });
});
