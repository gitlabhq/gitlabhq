import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import component from '~/packages_and_registries/settings/project/components/registry_settings_app.vue';
import SettingsForm from '~/packages_and_registries/settings/project/components/settings_form.vue';
import {
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import CleanupPolicyEnabledAlert from '~/packages_and_registries/shared/components/cleanup_policy_enabled_alert.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

import {
  expirationPolicyPayload,
  emptyExpirationPolicyPayload,
  containerExpirationPolicyData,
} from '../mock_data';

const localVue = createLocalVue();

describe('Registry Settings App', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    isAdmin: false,
    adminSettingsPath: 'settingsPath',
    enableHistoricEntries: false,
    helpPagePath: 'helpPagePath',
    showCleanupPolicyOnAlert: false,
  };

  const findSettingsComponent = () => wrapper.find(SettingsForm);
  const findAlert = () => wrapper.find(GlAlert);
  const findCleanupAlert = () => wrapper.findComponent(CleanupPolicyEnabledAlert);

  const mountComponent = (provide = defaultProvidedValues, config) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlSprintf,
        SettingsBlock,
      },
      mocks: {
        $toast: {
          show: jest.fn(),
        },
      },
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, resolver } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [[expirationPolicyQuery, resolver]];

    fakeApollo = createMockApollo(requestHandlers);
    mountComponent(provide, {
      localVue,
      apolloProvider: fakeApollo,
    });

    return requestHandlers.map((request) => request[1]);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('cleanup is on alert', () => {
    it('exist when showCleanupPolicyOnAlert is true and has the correct props', () => {
      mountComponent({
        ...defaultProvidedValues,
        showCleanupPolicyOnAlert: true,
      });

      expect(findCleanupAlert().exists()).toBe(true);
      expect(findCleanupAlert().props()).toMatchObject({
        projectPath: 'path',
      });
    });

    it('is hidden when showCleanupPolicyOnAlert is false', async () => {
      mountComponent();

      expect(findCleanupAlert().exists()).toBe(false);
    });
  });

  describe('isEdited status', () => {
    it.each`
      description                                  | apiResponse                       | workingCopy                                                   | result
      ${'empty response and no changes from user'} | ${emptyExpirationPolicyPayload()} | ${{}}                                                         | ${false}
      ${'empty response and changes from user'}    | ${emptyExpirationPolicyPayload()} | ${{ enabled: true }}                                          | ${true}
      ${'response and no changes'}                 | ${expirationPolicyPayload()}      | ${containerExpirationPolicyData()}                            | ${false}
      ${'response and changes'}                    | ${expirationPolicyPayload()}      | ${{ ...containerExpirationPolicyData(), nameRegex: '12345' }} | ${true}
      ${'response and empty'}                      | ${expirationPolicyPayload()}      | ${{}}                                                         | ${true}
    `('$description', async ({ apiResponse, workingCopy, result }) => {
      const requests = mountComponentWithApollo({
        provide: { ...defaultProvidedValues, enableHistoricEntries: true },
        resolver: jest.fn().mockResolvedValue(apiResponse),
      });
      await Promise.all(requests);

      findSettingsComponent().vm.$emit('input', workingCopy);

      await wrapper.vm.$nextTick();

      expect(findSettingsComponent().props('isEdited')).toBe(result);
    });
  });

  it('renders the setting form', async () => {
    const requests = mountComponentWithApollo({
      resolver: jest.fn().mockResolvedValue(expirationPolicyPayload()),
    });
    await Promise.all(requests);

    expect(findSettingsComponent().exists()).toBe(true);
  });

  describe('the form is disabled', () => {
    it('the form is hidden', () => {
      mountComponent();

      expect(findSettingsComponent().exists()).toBe(false);
    });

    it('shows an alert', () => {
      mountComponent();

      const text = findAlert().text();
      expect(text).toContain(UNAVAILABLE_FEATURE_INTRO_TEXT);
      expect(text).toContain(UNAVAILABLE_USER_FEATURE_TEXT);
    });

    describe('an admin is visiting the page', () => {
      it('shows the admin part of the alert message', () => {
        mountComponent({ ...defaultProvidedValues, isAdmin: true });

        const sprintf = findAlert().find(GlSprintf);
        expect(sprintf.text()).toBe('administration settings');
        expect(sprintf.find(GlLink).attributes('href')).toBe(
          defaultProvidedValues.adminSettingsPath,
        );
      });
    });
  });

  describe('fetchSettingsError', () => {
    beforeEach(() => {
      const requests = mountComponentWithApollo({
        resolver: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      return Promise.all(requests);
    });

    it('the form is hidden', () => {
      expect(findSettingsComponent().exists()).toBe(false);
    });

    it('shows an alert', () => {
      expect(findAlert().html()).toContain(FETCH_SETTINGS_ERROR_MESSAGE);
    });
  });

  describe('empty API response', () => {
    it.each`
      enableHistoricEntries | isShown
      ${true}               | ${true}
      ${false}              | ${false}
    `('is $isShown that the form is shown', async ({ enableHistoricEntries, isShown }) => {
      const requests = mountComponentWithApollo({
        provide: {
          ...defaultProvidedValues,
          enableHistoricEntries,
        },
        resolver: jest.fn().mockResolvedValue(emptyExpirationPolicyPayload()),
      });
      await Promise.all(requests);

      expect(findSettingsComponent().exists()).toBe(isShown);
    });
  });
});
