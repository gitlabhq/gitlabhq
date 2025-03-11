import { nextTick } from 'vue';
import { GlAlert, GlButton, GlForm, GlFormFields, GlFormTextarea } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import SettingsApp from '~/vscode_extension_marketplace/components/settings_app.vue';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/lib/logger');
jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('lodash/uniqueId', () => (x) => `${x}testUnique`);

const TEST_NEW_SETTINGS = { enabled: false, preset: 'open_vsx' };
const EXPECTED_FORM_ID = 'extension-marketplace-settings-form-testUnique';

describe('~/vscode_extension_marketplace/components/settings_app.vue', () => {
  let wrapper;
  let mockAdapter;
  let submitSpy;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SettingsApp, {
      propsData: {
        ...props,
      },
      stubs: {
        GlFormFields,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findFormFields = () => wrapper.findComponent(GlFormFields);
  const findTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findSaveButton = () => wrapper.findComponent(GlButton);
  const findErrorAlert = () => wrapper.findComponent(GlAlert);
  const findErrorAlertItems = () =>
    findErrorAlert()
      .findAll('li')
      .wrappers.map((x) => x.text());

  beforeEach(() => {
    gon.api_version = 'v4';
    submitSpy = jest.fn().mockReturnValue([200]);
    mockAdapter = new MockAdapter(axios);
    mockAdapter
      .onPut('/api/v4/application/settings')
      .reply(({ data }) => submitSpy(JSON.parse(data)));
  });

  afterEach(() => {
    mockAdapter.restore();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders form', () => {
      expect(findForm().attributes('id')).toBe(EXPECTED_FORM_ID);
    });

    it('renders form fields', () => {
      expect(findFormFields().props()).toMatchObject({
        formId: EXPECTED_FORM_ID,
        values: {
          settings: {},
        },
        fields: SettingsApp.FIELDS,
      });
    });

    it('renders settings textarea', () => {
      expect(findTextarea().attributes()).toMatchObject({
        id: 'gl-form-field-testUnique',
        value: '{}',
      });
    });

    it('renders save button', () => {
      expect(findSaveButton().attributes()).toMatchObject({
        type: 'submit',
        variant: 'confirm',
        category: 'primary',
        'aria-describedby': 'extensions-marketplace-settings-error-alert',
      });
      expect(findSaveButton().props('loading')).toBe(false);
      expect(findSaveButton().text()).toBe('Save changes');
    });
  });

  describe('when submitted', () => {
    beforeEach(async () => {
      createComponent();

      findTextarea().vm.$emit('input', JSON.stringify(TEST_NEW_SETTINGS));
      await nextTick();

      findFormFields().vm.$emit('submit');
    });

    it('triggers loading', () => {
      expect(findSaveButton().props('loading')).toBe(true);
    });

    it('makes submit request', () => {
      expect(submitSpy).toHaveBeenCalledTimes(1);
      expect(submitSpy).toHaveBeenCalledWith({
        vscode_extension_marketplace: TEST_NEW_SETTINGS,
      });
    });

    it('while loading, prevents extra submit', () => {
      findFormFields().vm.$emit('submit');
      findFormFields().vm.$emit('submit');

      expect(submitSpy).toHaveBeenCalledTimes(1);
    });

    it('when success, shows success message and stops loading', async () => {
      expect(toast).not.toHaveBeenCalled();

      await axios.waitForAll();

      expect(toast).toHaveBeenCalledTimes(1);
      expect(toast).toHaveBeenCalledWith('Extension marketplace settings updated.');
      expect(findSaveButton().props('loading')).toBe(false);
    });

    it('does not show error alert', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('when submitted and errored', () => {
    beforeEach(() => {
      submitSpy.mockReturnValue([400]);

      createComponent();

      findFormFields().vm.$emit('submit');
    });

    it('shows error message', async () => {
      expect(findErrorAlert().exists()).toBe(false);

      await axios.waitForAll();

      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().attributes('id')).toBe('extensions-marketplace-settings-error-alert');
      expect(findErrorAlert().props('dismissible')).toBe(false);
      expect(findErrorAlert().text()).toBe(
        'Failed to update extension marketplace settings. An unknown error occurred. Please try again.',
      );
    });

    it('logs error', async () => {
      expect(logError).not.toHaveBeenCalled();

      await axios.waitForAll();

      expect(logError).toHaveBeenCalledTimes(1);
      expect(logError).toHaveBeenCalledWith(
        'Failed to update extension marketplace settings. See error info:',
        expect.any(Error),
      );
    });

    it('updates state on textarea', async () => {
      expect(findTextarea().attributes('state')).toBe('true');

      await axios.waitForAll();

      expect(findTextarea().attributes('state')).toBeUndefined();
    });

    it('hides error message with another submit', async () => {
      await axios.waitForAll();

      expect(findErrorAlert().exists()).toBe(true);

      findFormFields().vm.$emit('submit');
      await nextTick();

      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('when submitted and server responds with structured error', () => {
    beforeEach(() => {
      submitSpy.mockReturnValue([
        400,
        { message: { vscode_extension_marketplace: ['LOREM', 'IPSUM'] } },
      ]);

      createComponent();

      findFormFields().vm.$emit('submit');
    });

    it('shows error message', async () => {
      expect(findErrorAlert().exists()).toBe(false);

      await axios.waitForAll();

      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('Failed to update extension marketplace settings.');
      expect(findErrorAlertItems()).toEqual([
        'vscode_extension_marketplace : LOREM',
        'vscode_extension_marketplace : IPSUM',
      ]);
    });
  });

  describe('with initialSettings', () => {
    beforeEach(() => {
      createComponent({
        initialSettings: TEST_NEW_SETTINGS,
      });
    });

    it('initializes the form with given settings', () => {
      expect(findTextarea().props('value')).toBe(JSON.stringify(TEST_NEW_SETTINGS, null, 2));
    });
  });
});
