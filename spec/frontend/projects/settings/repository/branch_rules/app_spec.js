import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlCollapsibleListbox, GlDisclosureDropdown } from '@gitlab/ui';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BranchRules from '~/projects/settings/repository/branch_rules/app.vue';
import BranchRule from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';
import branchRulesQuery from 'ee_else_ce/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import createBranchRuleMutation from '~/projects/settings/repository/branch_rules/graphql/mutations/create_branch_rule.mutation.graphql';
import BranchRuleModal from '~/projects/settings/components/branch_rule_modal.vue';
import getProtectableBranches from '~/projects/settings/graphql/queries/protectable_branches.query.graphql';

import { createAlert } from '~/alert';
import {
  branchRulesMockResponse,
  predefinedBranchRulesMockResponse,
  appProvideMock,
  createBranchRuleMockResponse,
  protectableBranchesMockResponse,
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
  const addRuleMutationSuccessHandler = jest.fn().mockResolvedValue(createBranchRuleMockResponse);
  const protectableBranchesSuccessHandler = jest
    .fn()
    .mockResolvedValue(protectableBranchesMockResponse);
  const addBranchRulesItems = [I18N.branchName, I18N.allBranches, I18N.allProtectedBranches];

  const createComponent = async ({
    glFeatures = { editBranchRules: true },
    queryHandler = branchRulesQuerySuccessHandler,
    mutationHandler = addRuleMutationSuccessHandler,
  } = {}) => {
    fakeApollo = createMockApollo([
      [branchRulesQuery, queryHandler],
      [getProtectableBranches, protectableBranchesSuccessHandler],
      [createBranchRuleMutation, mutationHandler],
    ]);

    wrapper = mountExtended(BranchRules, {
      apolloProvider: fakeApollo,
      provide: {
        ...appProvideMock,
        glFeatures,
      },
      stubs: {
        BranchRuleModal,
        GlDisclosureDropdown,
        GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
      directives: { GlModal: createMockDirective('gl-modal') },
    });

    await waitForPromises();
  };

  const findAllBranchRules = () => wrapper.findAllComponents(BranchRule);
  const findEmptyState = () => wrapper.findByTestId('empty');
  const findAddBranchRuleButton = () => wrapper.findByRole('button', I18N.addBranchRule);
  const findModal = () => wrapper.findComponent(GlModal);
  const findAddBranchRuleDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findCreateBranchRuleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => {
    setWindowLocation(TEST_HOST);
    createComponent();
  });

  it('renders branch rules', async () => {
    await nextTick();

    const { nodes } = branchRulesMockResponse.data.project.branchRules;

    expect(findAllBranchRules().length).toBe(nodes.length);

    expect(findAllBranchRules().at(0).props('name')).toBe(nodes[0].name);

    expect(findAllBranchRules().at(0).props('branchProtection')).toEqual(nodes[0].branchProtection);

    expect(findAllBranchRules().at(1).props('name')).toBe(nodes[1].name);

    expect(findAllBranchRules().at(1).props('branchProtection')).toEqual(nodes[1].branchProtection);
  });

  it('displays an error if branch rules query fails', async () => {
    await createComponent({ queryHandler: jest.fn().mockRejectedValue() });
    expect(createAlert).toHaveBeenCalledWith({ message: I18N.queryError });
  });

  it('displays an empty state if no branch rules are present', async () => {
    await createComponent({ queryHandler: jest.fn().mockRejectedValue() });
    expect(findEmptyState().text()).toBe(I18N.emptyState);
  });

  describe('Add branch rule', () => {
    it('renders an Add branch rule dropdown', () => {
      expect(findAddBranchRuleDropdown().props('toggleText')).toBe('Add branch rule');
    });

    it('renders a dropdown containing predefined branch rules with actions', () => {
      expect(findAddBranchRuleDropdown().props('items')).toEqual([
        { action: expect.any(Function), text: 'Branch name or pattern' },
        { action: expect.any(Function), text: 'All branches' },
        { action: expect.any(Function), text: 'All protected branches' },
      ]);
    });

    it('does not render predefined branch rules when they are already set', async () => {
      const { nodes } = predefinedBranchRulesMockResponse.data.project.branchRules;

      await createComponent({
        queryHandler: jest.fn().mockResolvedValue(predefinedBranchRulesMockResponse),
      });
      await findAddBranchRuleDropdown().vm.$emit('shown');
      await nextTick();

      expect(findAddBranchRuleDropdown().props('items').length).toEqual(
        addBranchRulesItems.length - nodes.length,
      );
    });

    it('renders a modal with correct props/attributes', () => {
      expect(findModal().props()).toMatchObject({
        title: I18N.createBranchRule,
        modalId: BRANCH_PROTECTION_MODAL_ID,
        actionCancel: {
          text: 'Cancel',
        },
        actionPrimary: {
          attributes: {
            disabled: true,
            variant: 'confirm',
          },
          text: 'Create protected branch',
        },
      });
    });

    it('when the primary modal action is clicked it calls create rule mutation', async () => {
      findCreateBranchRuleListbox().vm.$emit('select', 'main');
      await nextTick();
      findModal().vm.$emit('primary');
      await nextTick();
      await nextTick();
      expect(addRuleMutationSuccessHandler).toHaveBeenCalledWith({
        name: 'main',
        projectPath: 'some/project/path',
      });
    });

    it('shows alert when mutation fails', async () => {
      createComponent({ mutationHandler: jest.fn().mockRejectedValue() });
      findCreateBranchRuleListbox().vm.$emit('select', 'main');
      await nextTick();
      findModal().vm.$emit('primary');
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while creating branch rule.',
      });
    });
  });

  describe('Add branch rule when editBranchRules FF disabled', () => {
    beforeEach(() => {
      createComponent({ glFeatures: { editBranchRules: false } });
    });
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
