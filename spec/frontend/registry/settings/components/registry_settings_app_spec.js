import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import component from '~/registry/settings/components/registry_settings_app.vue';
import expirationPolicyQuery from '~/registry/settings/graphql/queries/get_expiration_policy.graphql';
import SettingsForm from '~/registry/settings/components/settings_form.vue';
import { FETCH_SETTINGS_ERROR_MESSAGE } from '~/registry/shared/constants';
import {
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
} from '~/registry/settings/constants';

import { expirationPolicyPayload, emptyExpirationPolicyPayload } from '../mock_data';

const localVue = createLocalVue();

describe('Registry Settings App', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    isAdmin: false,
    adminSettingsPath: 'settingsPath',
    enableHistoricEntries: false,
  };

  const findSettingsComponent = () => wrapper.find(SettingsForm);
  const findAlert = () => wrapper.find(GlAlert);

  const mountComponent = (provide = defaultProvidedValues, config) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlSprintf,
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

    return requestHandlers.map(request => request[1]);
  };

  afterEach(() => {
    wrapper.destroy();
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
