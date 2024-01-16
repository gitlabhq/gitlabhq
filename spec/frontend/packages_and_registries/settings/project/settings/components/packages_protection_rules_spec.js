import { GlTable, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackagesProtectionRules from '~/packages_and_registries/settings/project/components/packages_protection_rules.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import packagesProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_protection_rules.query.graphql';

import { packagesProtectionRuleQueryPayload, packagesProtectionRulesData } from '../mock_data';

Vue.use(VueApollo);

describe('Packages protection rules project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };
  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableRows = () => findTable().find('tbody').findAll('tr');

  const mountComponent = (mountFn = shallowMount, provide = defaultProvidedValues, config) => {
    wrapper = mountFn(PackagesProtectionRules, {
      stubs: {
        SettingsBlock,
      },
      provide,
      ...config,
    });
  };

  const createComponent = ({
    mountFn = shallowMount,
    provide = defaultProvidedValues,
    resolver = jest.fn().mockResolvedValue(packagesProtectionRuleQueryPayload()),
  } = {}) => {
    const requestHandlers = [[packagesProtectionRuleQuery, resolver]];

    fakeApollo = createMockApollo(requestHandlers);

    mountComponent(mountFn, provide, {
      apolloProvider: fakeApollo,
    });
  };

  it('renders the setting block with table', async () => {
    createComponent();

    await waitForPromises();

    expect(findSettingsBlock().exists()).toBe(true);
    expect(findTable().exists()).toBe(true);
  });

  describe('table package protection rules', () => {
    it('renders table with packages protection rules', async () => {
      createComponent({ mountFn: mount });

      await waitForPromises();

      expect(findTable().exists()).toBe(true);

      packagesProtectionRulesData.forEach((protectionRule, i) => {
        expect(findTableRows().at(i).text()).toContain(protectionRule.packageNamePattern);
        expect(findTableRows().at(i).text()).toContain(protectionRule.packageType);
        expect(findTableRows().at(i).text()).toContain(protectionRule.pushProtectedUpToAccessLevel);
      });
    });

    it('displays table in busy state and shows loading icon inside table', async () => {
      createComponent({ mountFn: mount });

      expect(findTableLoadingIcon().exists()).toBe(true);
      expect(findTableLoadingIcon().attributes('aria-label')).toBe('Loading');

      expect(findTable().attributes('aria-busy')).toBe('true');

      await waitForPromises();

      expect(findTableLoadingIcon().exists()).toBe(false);
      expect(findTable().attributes('aria-busy')).toBe('false');
    });

    it('renders table', async () => {
      createComponent();

      await waitForPromises();

      expect(findTable().exists()).toBe(true);
    });
  });
});
