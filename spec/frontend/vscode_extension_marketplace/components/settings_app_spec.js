import { nextTick } from 'vue';
import { GlAlert, GlAccordion, GlAccordionItem, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import SettingsApp from '~/vscode_extension_marketplace/components/settings_app.vue';
import SettingsForm from '~/vscode_extension_marketplace/components/settings_form.vue';
import toast from '~/vue_shared/plugins/global_toast';
import { PRESETS } from '../mock_data';

jest.mock('~/lib/logger');
jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('lodash/uniqueId', () => (x) => `${x}testUnique`);

const TEST_NEW_SETTINGS = { preset: 'open_vsx' };
const TEST_INIT_SETTINGS = {
  enabled: true,
  preset: 'custom',
  custom_values: {
    item_url: 'abc',
    service_url: 'def',
    resource_url_template: 'ghi',
  },
};

describe('~/vscode_extension_marketplace/components/settings_app.vue', () => {
  let wrapper;
  let mockAdapter;
  let submitSpy;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SettingsApp, {
      propsData: {
        presets: PRESETS,
        ...props,
      },
    });
  };

  const findAccordion = () => wrapper.findComponent(GlAccordion);
  const findAccordionItem = () => findAccordion().findComponent(GlAccordionItem);
  const findSettingsForm = () => findAccordionItem().findComponent(SettingsForm);
  const findToggle = () => wrapper.findComponent(GlToggle);
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

    it('renders toggle', () => {
      expect(findToggle().props()).toMatchObject({
        value: false,
        isLoading: false,
        label: 'Enable Extension Marketplace',
        help: 'Enable the VS Code extension marketplace for all users.',
        labelPosition: 'top',
      });
    });

    it('renders accordion and accordion item', () => {
      expect(findAccordion().props()).toMatchObject({
        headerLevel: 3,
      });

      expect(findAccordionItem().props()).toMatchObject({
        title: 'Extension registry settings',
      });
    });

    it('renders inner form', () => {
      expect(findSettingsForm().props()).toEqual({
        initialSettings: {},
        presets: PRESETS,
        submitButtonAttrs: {
          'aria-describedby': 'extension-marketplace-settings-error-alert',
          loading: false,
        },
      });
    });
  });

  describe('when enablement toggle is changed', () => {
    beforeEach(() => {
      createComponent();

      findToggle().vm.$emit('change', true);
    });

    it('triggers loading', () => {
      expect(findSettingsForm().props('submitButtonAttrs')).toEqual({
        'aria-describedby': 'extension-marketplace-settings-error-alert',
        loading: true,
      });

      expect(findToggle().props()).toMatchObject({
        value: false,
        isLoading: true,
      });
    });

    it('makes submit request', () => {
      expect(submitSpy).toHaveBeenCalledTimes(1);
      expect(submitSpy).toHaveBeenCalledWith({
        vscode_extension_marketplace_enabled: true,
      });
    });

    it('while loading, prevents extra submit', () => {
      findToggle().vm.$emit('change', true);
      findToggle().vm.$emit('change', true);

      expect(submitSpy).toHaveBeenCalledTimes(1);
    });

    it('when success, shows success message and stops loading', async () => {
      expect(toast).not.toHaveBeenCalled();

      await axios.waitForAll();

      expect(toast).toHaveBeenCalledTimes(1);
      expect(toast).toHaveBeenCalledWith('Extension marketplace settings updated.');
      expect(findToggle().props('isLoading')).toBe(false);
    });

    it('does not show error alert', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('with initial settings', () => {
    beforeEach(() => {
      createComponent({
        initialSettings: TEST_INIT_SETTINGS,
      });
    });

    it('initializes settings in toggle', () => {
      expect(findToggle().props('value')).toBe(true);
    });

    it('initializes settings in form', () => {
      expect(findSettingsForm().props('initialSettings')).toBe(TEST_INIT_SETTINGS);
    });

    it('when submitted, submits settings', async () => {
      expect(submitSpy).not.toHaveBeenCalled();

      findSettingsForm().vm.$emit('submit', TEST_NEW_SETTINGS);
      await waitForPromises();

      expect(submitSpy).toHaveBeenCalledTimes(1);
      expect(submitSpy).toHaveBeenCalledWith({
        vscode_extension_marketplace: {
          enabled: true,
          preset: 'open_vsx',
          custom_values: {
            item_url: 'abc',
            service_url: 'def',
            resource_url_template: 'ghi',
          },
        },
      });
    });
  });

  describe('when submitted and errored', () => {
    beforeEach(() => {
      submitSpy.mockReturnValue([400]);

      createComponent();

      findSettingsForm().vm.$emit('submit', {});
    });

    it('shows error message', async () => {
      expect(findErrorAlert().exists()).toBe(false);

      await axios.waitForAll();

      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().attributes('id')).toBe('extension-marketplace-settings-error-alert');
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

    it('hides error message with another submit', async () => {
      await axios.waitForAll();

      expect(findErrorAlert().exists()).toBe(true);

      findSettingsForm().vm.$emit('submit', TEST_NEW_SETTINGS);
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

      findSettingsForm().vm.$emit('submit', TEST_NEW_SETTINGS);
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
});
