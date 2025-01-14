import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';
import PackagesCleanupPolicyForm from '~/packages_and_registries/settings/project/components/packages_cleanup_policy_form.vue';
import { FETCH_SETTINGS_ERROR_MESSAGE } from '~/packages_and_registries/settings/project/constants';
import packagesCleanupPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_cleanup_policy.query.graphql';

import { packagesCleanupPolicyPayload, packagesCleanupPolicyData } from '../mock_data';

Vue.use(VueApollo);

describe('Packages cleanup policy project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFormComponent = () => wrapper.findComponent(PackagesCleanupPolicyForm);
  const findHeader = () => wrapper.find('h2');

  const mountComponent = (provide = defaultProvidedValues, config) => {
    wrapper = shallowMount(PackagesCleanupPolicy, {
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, resolver } = {}) => {
    const requestHandlers = [[packagesCleanupPolicyQuery, resolver]];

    fakeApollo = createMockApollo(requestHandlers);
    mountComponent(provide, {
      apolloProvider: fakeApollo,
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  it('renders the setting form', async () => {
    mountComponentWithApollo({
      resolver: jest.fn().mockResolvedValue(packagesCleanupPolicyPayload()),
    });
    await waitForPromises();

    expect(findHeader().text()).toBe('Manage storage used by package assets');
    expect(findFormComponent().exists()).toBe(true);
    expect(findFormComponent().props('value')).toEqual(packagesCleanupPolicyData);
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
});
