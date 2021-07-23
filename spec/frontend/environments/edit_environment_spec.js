import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EditEnvironment from '~/environments/components/edit_environment.vue';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/flash');

const DEFAULT_OPTS = {
  provide: {
    projectEnvironmentsPath: '/projects/environments',
    updateEnvironmentPath: '/proejcts/environments/1',
  },
  propsData: { environment: { name: 'foo', externalUrl: 'https://foo.example.com' } },
};

describe('~/environments/components/edit.vue', () => {
  let wrapper;
  let mock;
  let name;
  let url;
  let form;

  const createWrapper = (opts = {}) =>
    mountExtended(EditEnvironment, {
      ...DEFAULT_OPTS,
      ...opts,
    });

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createWrapper();
    name = wrapper.findByLabelText('Name');
    url = wrapper.findByLabelText('External URL');
    form = wrapper.findByRole('form', { name: 'Edit environment' });
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  const fillForm = async (expected, response) => {
    mock
      .onPut(DEFAULT_OPTS.provide.updateEnvironmentPath, {
        name: expected.name,
        external_url: expected.url,
      })
      .reply(...response);
    await name.setValue(expected.name);
    await url.setValue(expected.url);

    await form.trigger('submit');
    await waitForPromises();
  };

  it('sets the title to Edit environment', () => {
    const header = wrapper.findByRole('heading', { name: 'Edit environment' });
    expect(header.exists()).toBe(true);
  });

  it.each`
    input         | value
    ${() => name} | ${'test'}
    ${() => url}  | ${'https://example.org'}
  `('it changes the value of the input to $value', async ({ input, value }) => {
    await input().setValue(value);

    expect(input().element.value).toBe(value);
  });

  it('submits the updated environment on submit', async () => {
    const expected = { name: 'test', url: 'https://google.ca' };

    await fillForm(expected, [200, { path: '/test' }]);

    expect(visitUrl).toHaveBeenCalledWith('/test');
  });

  it('shows errors on error', async () => {
    const expected = { name: 'test', url: 'https://google.ca' };

    await fillForm(expected, [400, { message: ['name taken'] }]);

    expect(createFlash).toHaveBeenCalledWith({ message: 'name taken' });
  });
});
