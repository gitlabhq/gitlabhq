import { GlAlert, GlSprintf, GlLink, GlCard } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import {
  CONTAINER_CLEANUP_POLICY_EDIT_RULES,
  CONTAINER_CLEANUP_POLICY_SET_RULES,
  CONTAINER_CLEANUP_POLICY_RULES_DESCRIPTION,
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';

import {
  expirationPolicyPayload,
  emptyExpirationPolicyPayload,
  nullExpirationPolicyPayload,
} from '../mock_data';

describe('Container expiration policy project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    isAdmin: false,
    adminSettingsPath: 'settingsPath',
    cleanupSettingsPath: 'cleanupSettingsPath',
    enableHistoricEntries: false,
    helpPagePath: 'helpPagePath',
  };

  const findFormComponent = () => wrapper.findComponent(GlCard);
  const findDescription = () => wrapper.findByTestId('description');
  const findButton = () => wrapper.findByTestId('rules-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);

  const mountComponent = (provide = defaultProvidedValues, config) => {
    wrapper = shallowMountExtended(component, {
      stubs: {
        GlSprintf,
        SettingsBlock,
      },
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, resolver } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[expirationPolicyQuery, resolver]];

    fakeApollo = createMockApollo(requestHandlers);
    mountComponent(provide, {
      apolloProvider: fakeApollo,
    });
  };

  it('renders the setting form', async () => {
    mountComponentWithApollo({
      resolver: jest.fn().mockResolvedValue(expirationPolicyPayload()),
    });
    await waitForPromises();

    expect(findSettingsBlock().exists()).toBe(true);
    expect(findFormComponent().exists()).toBe(true);
    expect(findDescription().text()).toMatchInterpolatedText(
      CONTAINER_CLEANUP_POLICY_RULES_DESCRIPTION,
    );
    expect(findButton().text()).toMatchInterpolatedText(CONTAINER_CLEANUP_POLICY_EDIT_RULES);
    expect(findButton().attributes('href')).toBe(defaultProvidedValues.cleanupSettingsPath);
  });

  it('when loading does not render form or alert components', () => {
    mountComponentWithApollo({
      resolver: jest.fn().mockResolvedValue(),
    });

    expect(findFormComponent().exists()).toBe(false);
    expect(findAlert().exists()).toBe(false);
  });

  describe('the form is disabled', () => {
    it('hides the form', async () => {
      mountComponentWithApollo({
        resolver: jest.fn().mockResolvedValue(nullExpirationPolicyPayload()),
      });
      await waitForPromises();

      expect(findFormComponent().exists()).toBe(false);
    });

    it('shows an alert', async () => {
      mountComponentWithApollo({
        resolver: jest.fn().mockResolvedValue(nullExpirationPolicyPayload()),
      });
      await waitForPromises();

      const text = findAlert().text();
      expect(text).toContain(UNAVAILABLE_FEATURE_INTRO_TEXT);
      expect(text).toContain(UNAVAILABLE_USER_FEATURE_TEXT);
    });

    describe('an admin is visiting the page', () => {
      it('shows the admin part of the alert', async () => {
        mountComponentWithApollo({
          provide: { ...defaultProvidedValues, isAdmin: true },
          resolver: jest.fn().mockResolvedValue(nullExpirationPolicyPayload()),
        });
        await waitForPromises();

        const sprintf = findAlert().findComponent(GlSprintf);
        expect(sprintf.text()).toBe('administration settings');
        expect(sprintf.findComponent(GlLink).attributes('href')).toBe(
          defaultProvidedValues.adminSettingsPath,
        );
      });
    });
  });

  describe('fetchSettingsError', () => {
    beforeEach(async () => {
      mountComponentWithApollo({
        resolver: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      await waitForPromises();
    });

    it('the form is hidden', () => {
      expect(findFormComponent().exists()).toBe(false);
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
      mountComponentWithApollo({
        provide: {
          ...defaultProvidedValues,
          enableHistoricEntries,
        },
        resolver: jest.fn().mockResolvedValue(emptyExpirationPolicyPayload()),
      });
      await waitForPromises();

      expect(findFormComponent().exists()).toBe(isShown);
      if (isShown) {
        expect(findButton().text()).toMatchInterpolatedText(CONTAINER_CLEANUP_POLICY_SET_RULES);
        expect(findButton().attributes('href')).toBe(defaultProvidedValues.cleanupSettingsPath);
      }
    });
  });
});
