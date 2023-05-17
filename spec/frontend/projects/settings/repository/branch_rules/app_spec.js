import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BranchRules from '~/projects/settings/repository/branch_rules/app.vue';
import BranchRule from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';
import branchRulesQuery from 'ee_else_ce/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import { createAlert } from '~/alert';
import {
  branchRulesMockResponse,
  appProvideMock,
} from 'ee_else_ce_jest/projects/settings/repository/branch_rules/mock_data';
import {
  I18N,
  BRANCH_PROTECTION_MODAL_ID,
  PROTECTED_BRANCHES_ANCHOR,
} from '~/projects/settings/repository/branch_rules/constants';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { expandSection } from '~/settings_panels';
import { scrollToElement } from '~/lib/utils/common_utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

jest.mock('~/alert');
jest.mock('~/settings_panels');
jest.mock('~/lib/utils/common_utils');

Vue.use(VueApollo);

describe('Branch rules app', () => {
  let wrapper;
  let fakeApollo;

  const branchRulesQuerySuccessHandler = jest.fn().mockResolvedValue(branchRulesMockResponse);

  const createComponent = async ({ queryHandler = branchRulesQuerySuccessHandler } = {}) => {
    fakeApollo = createMockApollo([[branchRulesQuery, queryHandler]]);

    wrapper = mountExtended(BranchRules, {
      apolloProvider: fakeApollo,
      provide: appProvideMock,
      stubs: { GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }) },
      directives: { GlModal: createMockDirective('gl-modal') },
    });

    await waitForPromises();
  };

  const findAllBranchRules = () => wrapper.findAllComponents(BranchRule);
  const findEmptyState = () => wrapper.findByTestId('empty');
  const findAddBranchRuleButton = () => wrapper.findByRole('button', I18N.addBranchRule);
  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => createComponent());

  it('displays an error if branch rules query fails', async () => {
    await createComponent({ queryHandler: jest.fn().mockRejectedValue() });
    expect(createAlert).toHaveBeenCalledWith({ message: I18N.queryError });
  });

  it('displays an empty state if no branch rules are present', async () => {
    await createComponent({ queryHandler: jest.fn().mockRejectedValue() });
    expect(findEmptyState().text()).toBe(I18N.emptyState);
  });

  it('renders branch rules', () => {
    const { nodes } = branchRulesMockResponse.data.project.branchRules;

    expect(findAllBranchRules().length).toBe(nodes.length);

    expect(findAllBranchRules().at(0).props('name')).toBe(nodes[0].name);

    expect(findAllBranchRules().at(0).props('branchProtection')).toEqual(nodes[0].branchProtection);

    expect(findAllBranchRules().at(1).props('name')).toBe(nodes[1].name);

    expect(findAllBranchRules().at(1).props('branchProtection')).toEqual(nodes[1].branchProtection);
  });

  describe('Add branch rule', () => {
    it('renders an Add branch rule button', () => {
      expect(findAddBranchRuleButton().exists()).toBe(true);
    });

    it('renders a modal with correct props/attributes', () => {
      expect(findModal().props()).toMatchObject({
        modalId: BRANCH_PROTECTION_MODAL_ID,
        title: I18N.addBranchRule,
      });

      expect(findModal().attributes('ok-title')).toBe(I18N.createProtectedBranch);
    });

    it('renders correct modal id for the default action', () => {
      const binding = getBinding(findAddBranchRuleButton().element, 'gl-modal');

      expect(binding.value).toBe(BRANCH_PROTECTION_MODAL_ID);
    });

    it('renders the correct modal content', () => {
      expect(findModal().text()).toContain(I18N.branchRuleModalDescription);
      expect(findModal().text()).toContain(I18N.branchRuleModalContent);
    });

    it('when the primary modal action is clicked, takes user to the correct location', () => {
      findAddBranchRuleButton().trigger('click');
      findModal().vm.$emit('ok');

      expect(expandSection).toHaveBeenCalledWith(PROTECTED_BRANCHES_ANCHOR);
      expect(scrollToElement).toHaveBeenCalledWith(PROTECTED_BRANCHES_ANCHOR);
    });
  });
});
