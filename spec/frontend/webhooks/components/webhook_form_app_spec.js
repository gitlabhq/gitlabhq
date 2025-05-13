import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WebhookFormApp from '~/webhooks/components/webhook_form_app.vue';
import FormUrlApp from '~/webhooks/components/form_url_app.vue';
import FormCustomHeaders from '~/webhooks/components/form_custom_headers.vue';

describe('WebhookFormApp', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WebhookFormApp, {
      propsData: {
        ...props,
      },
    });
  };

  const findNameInput = () => wrapper.findByTestId('webhook-name');
  const findDescriptionInput = () => wrapper.findByTestId('webhook-description');
  const findFormUrlApp = () => wrapper.findComponent(FormUrlApp);
  const findFormCustomHeaders = () => wrapper.findComponent(FormCustomHeaders);

  beforeEach(() => {
    createComponent();
  });

  describe('name input', () => {
    it('renders name input', () => {
      expect(findNameInput().props('name')).toBe('hook[name]');
      expect(findNameInput().props('value')).toBe('');
    });

    it('uses initialName as initial value', () => {
      const initialName = 'Test Name';

      createComponent({
        props: {
          initialName,
        },
      });

      expect(findNameInput().props('value')).toBe(initialName);
    });
  });

  describe('description input', () => {
    it('renders description input', () => {
      expect(findDescriptionInput().attributes('name')).toBe('hook[description]');
      expect(findDescriptionInput().props('value')).toBe('');
    });

    it('uses initialDescription as initial value', async () => {
      const initialDescription = 'Test Description';

      createComponent({
        props: {
          initialDescription,
        },
      });
      await nextTick();

      expect(findDescriptionInput().props('value')).toBe(initialDescription);
    });
  });

  describe('FormUrlApp component', () => {
    it('renders FormUrlApp', () => {
      expect(findFormUrlApp().props()).toMatchObject({
        initialUrl: null,
        initialUrlVariables: [],
      });
    });

    it('passes initialUrl and initialUrlVariables to FormUrlApp', () => {
      const initialUrl = 'https://webhook.site';
      const initialUrlVariables = [{ key: 'test', value: 'value' }];

      createComponent({
        props: {
          initialUrl,
          initialUrlVariables,
        },
      });

      expect(findFormUrlApp().props()).toMatchObject({
        initialUrl,
        initialUrlVariables,
      });
    });
  });

  describe('FormCustomHeaders component', () => {
    it('renders FormCustomHeaders', () => {
      expect(findFormCustomHeaders().props()).toMatchObject({
        initialCustomHeaders: [],
      });
    });

    it('passes initialCustomHeaders to FormCustomHeaders', () => {
      const initialCustomHeaders = [{ key: 'Authorization', value: 'Bearer token' }];

      createComponent({
        props: {
          initialCustomHeaders,
        },
      });

      expect(findFormCustomHeaders().props()).toMatchObject({
        initialCustomHeaders,
      });
    });
  });
});
