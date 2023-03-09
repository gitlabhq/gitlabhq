import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewEnvironment from '~/environments/components/new_environment.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

const DEFAULT_OPTS = {
  provide: {
    projectEnvironmentsPath: '/projects/environments',
    protectedEnvironmentSettingsPath: '/projects/not_real/settings/ci_cd',
  },
};

describe('~/environments/components/new.vue', () => {
  let wrapper;
  let mock;
  let name;
  let url;
  let form;

  const createWrapper = (opts = {}) =>
    mountExtended(NewEnvironment, {
      ...DEFAULT_OPTS,
      ...opts,
    });

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createWrapper();
    name = wrapper.findByLabelText('Name');
    url = wrapper.findByLabelText('External URL');
    form = wrapper.findByRole('form', { name: 'New environment' });
  });

  afterEach(() => {
    mock.restore();
  });

  const showsLoading = () => wrapper.findComponent(GlLoadingIcon).exists();

  const submitForm = async (expected, response) => {
    mock
      .onPost(DEFAULT_OPTS.provide.projectEnvironmentsPath, {
        name: expected.name,
        external_url: expected.url,
      })
      .reply(...response);
    await name.setValue(expected.name);
    await url.setValue(expected.url);

    await form.trigger('submit');
    await waitForPromises();
  };

  it('sets the title to New environment', () => {
    const header = wrapper.findByRole('heading', { name: 'New environment' });
    expect(header.exists()).toBe(true);
  });

  it.each`
    input         | value
    ${() => name} | ${'test'}
    ${() => url}  | ${'https://example.org'}
  `('changes the value of the input to $value', async ({ input, value }) => {
    await input().setValue(value);

    expect(input().element.value).toBe(value);
  });

  it('shows loader after form is submitted', async () => {
    const expected = { name: 'test', url: 'https://google.ca' };

    expect(showsLoading()).toBe(false);

    await submitForm(expected, [HTTP_STATUS_OK, { path: '/test' }]);

    expect(showsLoading()).toBe(true);
  });

  it('submits the new environment on submit', async () => {
    const expected = { name: 'test', url: 'https://google.ca' };

    await submitForm(expected, [HTTP_STATUS_OK, { path: '/test' }]);

    expect(visitUrl).toHaveBeenCalledWith('/test');
  });

  it('shows errors on error', async () => {
    const expected = { name: 'test', url: 'https://google.ca' };

    await submitForm(expected, [HTTP_STATUS_BAD_REQUEST, { message: ['name taken'] }]);

    expect(createAlert).toHaveBeenCalledWith({ message: 'name taken' });
    expect(showsLoading()).toBe(false);
  });
});
