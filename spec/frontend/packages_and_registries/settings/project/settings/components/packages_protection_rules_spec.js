import { GlTable } from '@gitlab/ui';
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

  it('renders table with container registry protection rules', async () => {
    createComponent({ mountFn: mount });

    await waitForPromises();

    expect(findTable().exists()).toBe(true);

    packagesProtectionRulesData.forEach((protectionRule, i) => {
      expect(findTableRows().at(i).text()).toContain(protectionRule.packageNamePattern);
      expect(findTableRows().at(i).text()).toContain(protectionRule.packageType);
      expect(findTableRows().at(i).text()).toContain(protectionRule.pushProtectedUpToAccessLevel);
    });
  });

  it('renders table with pagination', async () => {
    createComponent();

    await waitForPromises();

    expect(findTable().exists()).toBe(true);
  });
});
