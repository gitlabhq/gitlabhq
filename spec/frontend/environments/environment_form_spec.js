import { GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentForm from '~/environments/components/environment_form.vue';

jest.mock('~/lib/utils/csrf');

const DEFAULT_PROPS = {
  environment: { name: '', externalUrl: '' },
  title: 'environment',
  cancelPath: '/cancel',
};

const PROVIDE = { protectedEnvironmentSettingsPath: '/projects/not_real/settings/ci_cd' };

describe('~/environments/components/form.vue', () => {
  let wrapper;

  const createWrapper = (propsData = {}, options = {}) =>
    mountExtended(EnvironmentForm, {
      provide: PROVIDE,
      ...options,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
    });

  describe('default', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('links to documentation regarding environments', () => {
      const link = wrapper.findByRole('link', { name: 'More information.' });
      expect(link.attributes('href')).toBe('/help/ci/environments/index.md');
    });

    it('links the cancel button to the cancel path', () => {
      const cancel = wrapper.findByRole('link', { name: 'Cancel' });

      expect(cancel.attributes('href')).toBe(DEFAULT_PROPS.cancelPath);
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

  it('shows a loading icon while loading', () => {
    wrapper = createWrapper({ loading: true });
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe('when a new environment is being created', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        environment: {
          name: '',
          externalUrl: '',
        },
      });
    });

    it('renders an enabled "Name" field', () => {
      const nameInput = wrapper.findByLabelText('Name');

      expect(nameInput.attributes().disabled).toBeUndefined();
      expect(nameInput.element.value).toBe('');
    });

    it('renders an "External URL" field', () => {
      const urlInput = wrapper.findByLabelText('External URL');

      expect(urlInput.element.value).toBe('');
    });

    it('does not show protected environment documentation', () => {
      expect(wrapper.findByRole('link', { name: 'Protected environments' }).exists()).toBe(false);
    });
  });

  describe('when no protected environment link is provided', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        provide: {},
      });
    });

    it('does not show protected environment documentation', () => {
      expect(wrapper.findByRole('link', { name: 'Protected environments' }).exists()).toBe(false);
    });
  });

  describe('when an existing environment is being edited', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        environment: {
          id: 1,
          name: 'test',
          externalUrl: 'https://example.com',
        },
      });
    });

    it('renders a disabled "Name" field', () => {
      const nameInput = wrapper.findByLabelText('Name');

      expect(nameInput.attributes().disabled).toBe('disabled');
      expect(nameInput.element.value).toBe('test');
    });

    it('renders an "External URL" field', () => {
      const urlInput = wrapper.findByLabelText('External URL');

      expect(urlInput.element.value).toBe('https://example.com');
    });
  });
});
