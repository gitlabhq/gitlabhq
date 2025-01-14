import { GlAlert, GlSprintf, GlLink, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import {
  CONTAINER_CLEANUP_POLICY_TITLE,
  CONTAINER_CLEANUP_POLICY_EDIT_RULES,
  CONTAINER_CLEANUP_POLICY_SET_RULES,
  CONTAINER_CLEANUP_POLICY_DESCRIPTION,
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyEnabledQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy_enabled.query.graphql';
import ContainerExpirationPolicyEnabledText from '~/packages_and_registries/settings/project/components/container_expiration_policy_enabled_text.vue';

import {
  containerTagsExpirationPolicyData,
  expirationPolicyEnabledPayload,
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

  const findCard = () => wrapper.findComponent(GlCard);
  const findHeader = () => findCard().find('h2');
  const findDescription = () => wrapper.findByTestId('description');
  const findButton = () => wrapper.findByTestId('rules-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEnabledText = () => wrapper.findComponent(ContainerExpirationPolicyEnabledText);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const mountComponent = (provide = defaultProvidedValues, config) => {
    wrapper = shallowMountExtended(component, {
      stubs: {
        GlSprintf,
      },
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, resolver } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[expirationPolicyEnabledQuery, resolver]];

    fakeApollo = createMockApollo(requestHandlers);
    mountComponent(provide, {
      apolloProvider: fakeApollo,
    });
  };

  it('renders the setting form', async () => {
    mountComponentWithApollo({
      resolver: jest.fn().mockResolvedValue(expirationPolicyEnabledPayload),
    });
    await waitForPromises();

    expect(findHeader().text()).toBe(CONTAINER_CLEANUP_POLICY_TITLE);
    expect(findDescription().text()).toMatchInterpolatedText(CONTAINER_CLEANUP_POLICY_DESCRIPTION);
    expect(findButton().text()).toMatchInterpolatedText(CONTAINER_CLEANUP_POLICY_EDIT_RULES);
    expect(findButton().attributes('href')).toBe(defaultProvidedValues.cleanupSettingsPath);
    expect(findLoader().exists()).toBe(false);
    expect(findEnabledText().props('nextRunAt')).toBe(
      containerTagsExpirationPolicyData().nextRunAt,
    );
  });

  it('when loading does not render alert components', () => {
    mountComponentWithApollo({
      resolver: jest.fn().mockResolvedValue(),
    });

    expect(findCard().exists()).toBe(true);
    expect(findLoader().exists()).toBe(true);
    expect(findAlert().exists()).toBe(false);
    expect(findButton().exists()).toBe(false);
  });

  describe('when API returns `null`', () => {
    it('the button is hidden', async () => {
      mountComponentWithApollo({
        resolver: jest.fn().mockResolvedValue(nullExpirationPolicyPayload()),
      });
      await waitForPromises();

      expect(findButton().exists()).toBe(false);
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

    it('show the card', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('the button is hidden', () => {
      expect(findButton().exists()).toBe(false);
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
    `('is $isShown that the policy is shown', async ({ enableHistoricEntries, isShown }) => {
      mountComponentWithApollo({
        provide: {
          ...defaultProvidedValues,
          enableHistoricEntries,
        },
        resolver: jest.fn().mockResolvedValue(emptyExpirationPolicyPayload()),
      });
      await waitForPromises();

      expect(findCard().exists()).toBe(true);
      if (isShown) {
        expect(findButton().text()).toMatchInterpolatedText(CONTAINER_CLEANUP_POLICY_SET_RULES);
        expect(findButton().attributes('href')).toBe(defaultProvidedValues.cleanupSettingsPath);
        expect(wrapper.findByTestId('empty-cleanup-policy').text()).toBe(
          'Registry cleanup disabled. Either no cleanup policies are enabled, or this project has no container images.',
        );
      } else {
        expect(findButton().exists()).toBe(false);
        expect(findAlert().html()).toContain(FETCH_SETTINGS_ERROR_MESSAGE);
      }
    });
  });
});
