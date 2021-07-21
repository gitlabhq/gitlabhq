import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentForm from '~/environments/components/environment_form.vue';

jest.mock('~/lib/utils/csrf');

const DEFAULT_OPTS = {
  propsData: {
    environment: { name: '', externalUrl: '' },
    title: 'environment',
    cancelPath: '/cancel',
  },
};

describe('~/environments/components/form.vue', () => {
  let wrapper;

  const createWrapper = (opts = {}) =>
    mountExtended(EnvironmentForm, {
      ...DEFAULT_OPTS,
      ...opts,
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('links to documentation regarding environments', () => {
    const link = wrapper.findByRole('link', { name: 'More information' });
    expect(link.attributes('href')).toBe('/help/ci/environments/index.md');
  });

  it('links the cancel button to the cancel path', () => {
    const cancel = wrapper.findByRole('link', { name: 'Cancel' });

    expect(cancel.attributes('href')).toBe(DEFAULT_OPTS.propsData.cancelPath);
  });

  describe('name input', () => {
    let name;

    beforeEach(() => {
      name = wrapper.findByLabelText('Name');
    });

    it('should emit changes to the name', async () => {
      await name.setValue('test');
      await name.trigger('blur');

      expect(wrapper.emitted('change')).toEqual([[{ name: 'test', externalUrl: '' }]]);
    });

    it('should validate that the name is required', async () => {
      await name.setValue('');
      await name.trigger('blur');

      expect(wrapper.findByText('This field is required').exists()).toBe(true);
      expect(name.attributes('aria-invalid')).toBe('true');
    });
  });

  describe('url input', () => {
    let url;

    beforeEach(() => {
      url = wrapper.findByLabelText('External URL');
    });

    it('should emit changes to the url', async () => {
      await url.setValue('https://example.com');
      await url.trigger('blur');

      expect(wrapper.emitted('change')).toEqual([
        [{ name: '', externalUrl: 'https://example.com' }],
      ]);
    });

    it('should validate that the url is required', async () => {
      await url.setValue('example.com');
      await url.trigger('blur');

      expect(wrapper.findByText('The URL should start with http:// or https://').exists()).toBe(
        true,
      );
      expect(url.attributes('aria-invalid')).toBe('true');
    });
  });

  it('submits when the form does', async () => {
    await wrapper.findByRole('form', { title: 'environment' }).trigger('submit');

    expect(wrapper.emitted('submit')).toEqual([[]]);
  });
});
