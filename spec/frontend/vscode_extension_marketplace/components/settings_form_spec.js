import { GlForm, GlFormFields, GlToggle, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import SettingsForm from '~/vscode_extension_marketplace/components/settings_form.vue';
import { PRESETS } from '../mock_data';

jest.mock('lodash/uniqueId', () => (x) => `${x}uniqueId`);

const TEST_FORM_ID = 'extension-marketplace-settings-form-uniqueId';
const TEST_SUBMIT_BUTTON_ATTRS = {
  'aria-describedby': 'extension-marketplace-settings-error-alert',
};
const TEST_CUSTOM_VALUES = {
  item_url: 'abc',
  service_url: 'def',
  resource_url_template: 'ghi',
};

describe('~/vscode_extension_marketplace/components/settings_form.vue', () => {
  let wrapper;

  const findForm = () => wrapper.findComponent(GlForm);
  const findFormFields = () => findForm().findComponent(GlFormFields);
  const findOpenVsxToggle = () => findFormFields().findComponent(GlToggle);
  const findButton = () => findForm().findComponent(GlButton);

  const createComponent = (props = {}) => {
    wrapper = mount(SettingsForm, {
      propsData: {
        presets: PRESETS,
        submitButtonAttrs: TEST_SUBMIT_BUTTON_ATTRS,
        ...props,
      },
      stubs: {
        GlFormFields,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders form', () => {
      expect(findForm().attributes('id')).toBe(TEST_FORM_ID);
    });

    it('renders form fields', () => {
      const expectedInputAttrs = {
        readonly: true,
        'aria-description':
          'Disable Open VSX extension registry to set a custom value for this field.',
        width: 'lg',
      };

      expect(findFormFields().props()).toEqual({
        formId: TEST_FORM_ID,
        serverValidations: {},
        fields: {
          useOpenVsx: {
            label: 'Use Open VSX extension registry',
          },
          presetItemUrl: {
            label: 'Item URL',
            inputAttrs: expectedInputAttrs,
          },
          presetServiceUrl: {
            label: 'Service URL',
            inputAttrs: expectedInputAttrs,
          },
          presetResourceUrlTemplate: {
            label: 'Resource URL Template',
            inputAttrs: expectedInputAttrs,
          },
        },
        values: {
          useOpenVsx: true,
          presetItemUrl: 'https://open-vsx.org/vscode/item',
          presetResourceUrlTemplate:
            'https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}',
          presetServiceUrl: 'https://open-vsx.org/vscode/gallery',
        },
      });
    });

    it('renders open vsx toggle', () => {
      expect(findOpenVsxToggle().props()).toMatchObject({
        value: true,
        label: 'Use Open VSX extension registry',
        labelPosition: 'hidden',
      });
    });

    it('renders save button', () => {
      expect(findButton().props()).toMatchObject({
        type: 'submit',
        variant: 'confirm',
        category: 'primary',
      });
      expect(findButton().attributes()).toMatchObject(TEST_SUBMIT_BUTTON_ATTRS);
    });
  });

  describe('with preset=open_vsx and custom_values', () => {
    beforeEach(() => {
      createComponent({
        initialSettings: {
          custom_values: TEST_CUSTOM_VALUES,
        },
      });
    });

    it('changes values when openvsx is toggled', async () => {
      // NOTE: gl-form-fields emits `input` on mount to only include fiels created with
      expect(findFormFields().props('values')).toEqual({
        useOpenVsx: true,
        presetItemUrl: 'https://open-vsx.org/vscode/item',
        presetServiceUrl: 'https://open-vsx.org/vscode/gallery',
        presetResourceUrlTemplate:
          'https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}',
      });

      await findOpenVsxToggle().vm.$emit('change', false);

      expect(findFormFields().props('values')).toEqual({
        useOpenVsx: false,
        presetItemUrl: 'https://open-vsx.org/vscode/item',
        presetServiceUrl: 'https://open-vsx.org/vscode/gallery',
        presetResourceUrlTemplate:
          'https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}',
        itemUrl: 'abc',
        serviceUrl: 'def',
        resourceUrlTemplate: 'ghi',
      });
    });
  });

  describe('with preset=custom and custom_values', () => {
    beforeEach(() => {
      createComponent({
        initialSettings: {
          custom_values: TEST_CUSTOM_VALUES,
          preset: 'custom',
        },
      });
    });

    it('stores custom values when preset is changed back and forth', async () => {
      await findFormFields().vm.$emit('input', {
        useOpenVsx: false,
        itemUrl: 'xyz',
        serviceUrl: 'xyz',
        resourceUrlTemplate: 'xyz',
      });
      await findOpenVsxToggle().vm.$emit('change', true);

      expect(findFormFields().props('values')).toEqual({
        useOpenVsx: true,
        itemUrl: 'xyz',
        serviceUrl: 'xyz',
        resourceUrlTemplate: 'xyz',
        presetItemUrl: 'https://open-vsx.org/vscode/item',
        presetServiceUrl: 'https://open-vsx.org/vscode/gallery',
        presetResourceUrlTemplate:
          'https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}',
      });

      await findOpenVsxToggle().vm.$emit('change', false);

      expect(findFormFields().props('values')).toEqual({
        useOpenVsx: false,
        itemUrl: 'xyz',
        serviceUrl: 'xyz',
        resourceUrlTemplate: 'xyz',
        presetItemUrl: 'https://open-vsx.org/vscode/item',
        presetServiceUrl: 'https://open-vsx.org/vscode/gallery',
        presetResourceUrlTemplate:
          'https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}',
      });
    });

    it('renders customizable fields', () => {
      expect(findFormFields().props('fields')).toEqual(
        expect.objectContaining({
          itemUrl: {
            label: 'Item URL',
            inputAttrs: {
              placeholder: 'https://...',
              width: 'lg',
            },
            validators: expect.any(Array),
          },
          serviceUrl: {
            label: 'Service URL',
            inputAttrs: {
              placeholder: 'https://...',
              width: 'lg',
            },
            validators: expect.any(Array),
          },
          resourceUrlTemplate: {
            label: 'Resource URL Template',
            inputAttrs: {
              placeholder: 'https://...',
              width: 'lg',
            },
            validators: expect.any(Array),
          },
        }),
      );
    });

    it.each`
      fieldName                | value                    | expectation
      ${'itemUrl'}             | ${''}                    | ${'A valid URL is required.'}
      ${'itemUrl'}             | ${'abc def'}             | ${'A valid URL is required.'}
      ${'itemUrl'}             | ${'https://example.com'} | ${''}
      ${'serviceUrl'}          | ${''}                    | ${'A valid URL is required.'}
      ${'serviceUrl'}          | ${'abc def'}             | ${'A valid URL is required.'}
      ${'serviceUrl'}          | ${'https://example.com'} | ${''}
      ${'resourceUrlTemplate'} | ${''}                    | ${'A valid URL is required.'}
      ${'resourceUrlTemplate'} | ${'abc def'}             | ${'A valid URL is required.'}
      ${'resourceUrlTemplate'} | ${'https://example.com'} | ${''}
    `(
      'validates $fieldName where $value is "$expectation"',
      ({ fieldName, value, expectation }) => {
        const field = findFormFields().props('fields')[fieldName];

        const result = field.validators.reduce((msg, validator) => msg || validator(value), '');

        expect(result).toBe(expectation);
      },
    );
  });
});
