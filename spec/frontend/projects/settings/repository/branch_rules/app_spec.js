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

import { createAlert } from '~/alert';
import {
  branchRulesMockResponse,
  appProvideMock,
  createBranchRuleMockResponse,
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
  const openBranches = [
    { text: 'branch1', id: 'branch1', title: 'branch1' },
    { text: 'branch2', id: 'branch2', title: 'branch2' },
  ];
  const branchRulesQuerySuccessHandler = jest.fn().mockResolvedValue(branchRulesMockResponse);
  const addRuleMutationSuccessHandler = jest.fn().mockResolvedValue(createBranchRuleMockResponse);

  const createComponent = async ({
    glFeatures = { addBranchRule: true },
    queryHandler = branchRulesQuerySuccessHandler,
    mutationHandler = addRuleMutationSuccessHandler,
  } = {}) => {
    fakeApollo = createMockApollo([
      [branchRulesQuery, queryHandler],
      [createBranchRuleMutation, mutationHandler],
    ]);

    wrapper = mountExtended(BranchRules, {
      apolloProvider: fakeApollo,
      provide: {
        ...appProvideMock,
        glFeatures,
      },
      stubs: {
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
    window.gon = {
      open_branches: openBranches,
    };
    setWindowLocation(TEST_HOST);
  });

  beforeEach(() => createComponent());

  it('renders branch rules', () => {
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

    it('renders a modal with correct props/attributes', () => {
      expect(findModal().props()).toMatchObject({
        title: I18N.createBranchRule,
        modalId: BRANCH_PROTECTION_MODAL_ID,
        actionCancel: {
          text: 'Create branch rule',
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

    it('renders listbox with branch names', () => {
      expect(findCreateBranchRuleListbox().exists()).toBe(true);
      expect(findCreateBranchRuleListbox().props('items')).toHaveLength(openBranches.length);
      expect(findCreateBranchRuleListbox().props('toggleText')).toBe(
        'Select Branch or create wildcard',
      );
    });

    it('when the primary modal action is clicked it calls create rule mutation', async () => {
      findCreateBranchRuleListbox().vm.$emit('select', openBranches[0].text);
      await nextTick();
      findModal().vm.$emit('primary');
      await nextTick();
      await nextTick();
      expect(addRuleMutationSuccessHandler).toHaveBeenCalledWith({
        name: 'branch1',
        projectPath: 'some/project/path',
      });
    });

    it('shows alert when mutation fails', async () => {
      createComponent({ mutationHandler: jest.fn().mockRejectedValue() });
      findCreateBranchRuleListbox().vm.$emit('select', openBranches[0].text);
      await nextTick();
      findModal().vm.$emit('primary');
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while creating branch rule.',
      });
    });
  });

  describe('Add branch rule when addBranchRule FF disabled', () => {
    beforeEach(() => {
      window.gon.open_branches = openBranches;
      createComponent({ glFeatures: { addBranchRule: false } });
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
