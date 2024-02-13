import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackagesProtectionRules from '~/packages_and_registries/settings/project/components/packages_protection_rules.vue';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
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
  const findTable = () => extendedWrapper(wrapper.findByRole('table', /protected packages/i));
  const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
  const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findProtectionRuleForm = () => wrapper.findComponent(PackagesProtectionRuleForm);
  const findAddProtectionRuleButton = () =>
    wrapper.findByRole('button', { name: /add package protection rule/i });

  const mountComponent = (mountFn = shallowMount, provide = defaultProvidedValues, config) => {
    wrapper = mountFn(PackagesProtectionRules, {
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
    createComponent({ mountFn: mountExtended });

    await waitForPromises();

    expect(findSettingsBlock().exists()).toBe(true);
    expect(findTable().exists()).toBe(true);
  });

  describe('table "package protection rules"', () => {
    it('renders table with packages protection rules', async () => {
      createComponent({ mountFn: mountExtended });

      await waitForPromises();

      expect(findTable().exists()).toBe(true);

      packagesProtectionRuleQueryPayload().data.project.packagesProtectionRules.nodes.forEach(
        (protectionRule, i) => {
          expect(findTableRow(i).text()).toContain(protectionRule.packageNamePattern);
          expect(findTableRow(i).text()).toContain('npm');
          expect(findTableRow(i).text()).toContain('Maintainer');
        },
      );
    });

    it('displays table in busy state and shows loading icon inside table', async () => {
      createComponent({ mountFn: mountExtended });

      expect(findTableLoadingIcon().exists()).toBe(true);
      expect(findTableLoadingIcon().attributes('aria-label')).toBe('Loading');

      expect(findTable().attributes('aria-busy')).toBe('true');

      await waitForPromises();

      expect(findTableLoadingIcon().exists()).toBe(false);
      expect(findTable().attributes('aria-busy')).toBe('false');
    });

    it('calls graphql api query', () => {
      const resolver = jest.fn().mockResolvedValue(packagesProtectionRuleQueryPayload());
      createComponent({ resolver });

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ projectPath: defaultProvidedValues.projectPath }),
      );
    });

    describe('table pagination', () => {
      const findPagination = () => wrapper.findComponent(GlKeysetPagination);

      it('renders pagination', async () => {
        createComponent({ mountFn: mountExtended });

        await waitForPromises();

        expect(findPagination().exists()).toBe(true);
        expect(findPagination().props()).toMatchObject({
          endCursor: '10',
          startCursor: '0',
          hasNextPage: true,
          hasPreviousPage: false,
        });
      });

      it('calls initial graphql api query with pagination information', () => {
        const resolver = jest.fn().mockResolvedValue(packagesProtectionRuleQueryPayload());
        createComponent({ resolver });

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({
            projectPath: defaultProvidedValues.projectPath,
            first: 10,
          }),
        );
      });

      describe('when button "Previous" is clicked', () => {
        const resolver = jest
          .fn()
          .mockResolvedValueOnce(
            packagesProtectionRuleQueryPayload({
              nodes: packagesProtectionRulesData.slice(10),
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: true,
                startCursor: '10',
                endCursor: '16',
              },
            }),
          )
          .mockResolvedValueOnce(packagesProtectionRuleQueryPayload());

        const findPaginationButtonPrev = () =>
          extendedWrapper(findPagination()).findByRole('button', { name: 'Previous' });

        beforeEach(async () => {
          createComponent({ mountFn: mountExtended, resolver });

          await waitForPromises();

          findPaginationButtonPrev().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(resolver).toHaveBeenCalledTimes(2);
          expect(resolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              before: '10',
              last: 10,
              projectPath: 'path',
            }),
          );
        });
      });

      describe('when button "Next" is clicked', () => {
        const resolver = jest
          .fn()
          .mockResolvedValueOnce(packagesProtectionRuleQueryPayload())
          .mockResolvedValueOnce(
            packagesProtectionRuleQueryPayload({
              nodes: packagesProtectionRulesData.slice(10),
              pageInfo: {
                hasNextPage: true,
                hasPreviousPage: false,
                startCursor: '1',
                endCursor: '10',
              },
            }),
          );

        const findPaginationButtonNext = () =>
          extendedWrapper(findPagination()).findByRole('button', { name: 'Next' });

        beforeEach(async () => {
          createComponent({ mountFn: mountExtended, resolver });

          await waitForPromises();

          findPaginationButtonNext().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(resolver).toHaveBeenCalledTimes(2);
          expect(resolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              after: '10',
              first: 10,
              projectPath: 'path',
            }),
          );
        });
      });
    });
  });

  it('does not initially render package protection form', async () => {
    createComponent({ mountFn: mountExtended });

    await waitForPromises();

    expect(findAddProtectionRuleButton().isVisible()).toBe(true);
    expect(findProtectionRuleForm().exists()).toBe(false);
  });

  describe('button "Add protection rule"', () => {
    it('button exists', async () => {
      createComponent({ mountFn: mountExtended });

      await waitForPromises();

      expect(findAddProtectionRuleButton().isVisible()).toBe(true);
    });

    describe('when button is clicked', () => {
      beforeEach(async () => {
        createComponent({ mountFn: mountExtended });

        await waitForPromises();

        await findAddProtectionRuleButton().trigger('click');
      });

      it('renders package protection form', () => {
        expect(findProtectionRuleForm().isVisible()).toBe(true);
      });

      it('disables the button "add protection rule"', () => {
        expect(findAddProtectionRuleButton().attributes('disabled')).toBeDefined();
      });
    });
  });

  describe('form "add protection rule"', () => {
    let resolver;

    beforeEach(async () => {
      resolver = jest.fn().mockResolvedValue(packagesProtectionRuleQueryPayload());

      createComponent({ resolver, mountFn: mountExtended });

      await waitForPromises();

      await findAddProtectionRuleButton().trigger('click');
    });

    it('handles event "submit"', async () => {
      await findProtectionRuleForm().vm.$emit('submit');

      expect(resolver).toHaveBeenCalledTimes(2);

      expect(findProtectionRuleForm().exists()).toBe(false);
      expect(findAddProtectionRuleButton().attributes('disabled')).not.toBeDefined();
    });

    it('handles event "cancel"', async () => {
      await findProtectionRuleForm().vm.$emit('cancel');

      expect(resolver).toHaveBeenCalledTimes(1);

      expect(findProtectionRuleForm().exists()).toBe(false);
      expect(findAddProtectionRuleButton().attributes()).not.toHaveProperty('disabled');
    });
  });
});
