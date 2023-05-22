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
import { __ } from '~/locale';
import createMockApollo from '../__helpers__/mock_apollo_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

const environment = { id: '1', name: 'foo', externalUrl: 'https://foo.example.com' };
const resolvedEnvironment = { project: { id: '1', environment } };

const provide = {
  projectEnvironmentsPath: '/projects/environments',
  updateEnvironmentPath: '/projects/environments/1',
  protectedEnvironmentSettingsPath: '/projects/1/settings/ci_cd',
  projectPath: '/path/to/project',
  environmentName: environment.name,
};

describe('~/environments/components/edit.vue', () => {
  Vue.use(VueApollo);

  let wrapper;
  let mock;

  const createWrapper = () => {
    const mockApollo = createMockApollo([
      [getEnvironment, jest.fn().mockResolvedValue({ data: resolvedEnvironment })],
    ]);

    return mountExtended(EditEnvironment, {
      provide,
      apolloProvider: mockApollo,
    });
  };

  afterEach(() => {
    mock.restore();
  });

  const findNameInput = () => wrapper.findByLabelText(__('Name'));
  const findExternalUrlInput = () => wrapper.findByLabelText(__('External URL'));
  const findForm = () => wrapper.findByRole('form', { name: __('Edit environment') });

  const showsLoading = () => wrapper.findComponent(GlLoadingIcon).exists();

  const submitForm = async (expected, response) => {
    mock
      .onPut(provide.updateEnvironmentPath, {
        external_url: expected.url,
        id: '1',
      })
      .reply(...response);
    await findExternalUrlInput().setValue(expected.url);

    await findForm().trigger('submit');
    await waitForPromises();
  };

  describe('default', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);
      wrapper = createWrapper();
      await waitForPromises();
    });

    it('sets the title to Edit environment', () => {
      const header = wrapper.findByRole('heading', { name: __('Edit environment') });
      expect(header.exists()).toBe(true);
    });

    it('shows loader after form is submitted', async () => {
      const expected = { url: 'https://google.ca' };

      expect(showsLoading()).toBe(false);

      await submitForm(expected, [HTTP_STATUS_OK, { path: '/test' }]);

      expect(showsLoading()).toBe(true);
    });

    it('submits the updated environment on submit', async () => {
      const expected = { url: 'https://google.ca' };

      await submitForm(expected, [HTTP_STATUS_OK, { path: '/test' }]);

      expect(visitUrl).toHaveBeenCalledWith('/test');
    });

    it('shows errors on error', async () => {
      const expected = { url: 'https://google.ca' };

      await submitForm(expected, [HTTP_STATUS_BAD_REQUEST, { message: ['uh oh!'] }]);

      expect(createAlert).toHaveBeenCalledWith({ message: 'uh oh!' });
      expect(showsLoading()).toBe(false);
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

  describe('when environment query is loading', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders loading icon', () => {
      expect(showsLoading()).toBe(true);
    });
  });
});
