import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlButton } from '@gitlab/ui';
import { sprintf } from '~/locale';
import * as util from '~/lib/utils/url_utility';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import RuleView from '~/projects/settings/branch_rules/components/view/index.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import Protection from '~/projects/settings/branch_rules/components/view/protection.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  REQUIRED_ICON,
  NOT_REQUIRED_ICON,
  REQUIRED_ICON_CLASS,
  NOT_REQUIRED_ICON_CLASS,
  DELETE_RULE_MODAL_ID,
} from '~/projects/settings/branch_rules/components/view/constants';
import branchRulesQuery from 'ee_else_ce/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import deleteBranchRuleMutation from '~/projects/settings/branch_rules/mutations/branch_rule_delete.mutation.graphql';
import {
  deleteBranchRuleMockResponse,
  branchProtectionsMockResponse,
  matchingBranchesCount,
} from 'ee_else_ce_jest/projects/settings/branch_rules/components/view/mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockReturnValue('main'),
  mergeUrlParams: jest.fn().mockReturnValue('/branches?state=all&search=%5Emain%24'),
  joinPaths: jest.fn(),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

jest.mock('~/alert');

Vue.use(VueApollo);
useMockLocationHelper();

const protectionMockProps = {
  headerLinkHref: 'protected/branches',
  headerLinkTitle: I18N.manageProtectionsLinkTitle,
};
const roles = [
  { accessLevelDescription: 'Maintainers' },
  { accessLevelDescription: 'Maintainers + Developers' },
];

describe('View branch rules', () => {
  let wrapper;
  let fakeApollo;
  const projectPath = 'test/testing';
  const protectedBranchesPath = 'protected/branches';
  const branchRulesPath = '/-/settings/repository#branch_rules';
  const branchProtectionsMockRequestHandler = (response = branchProtectionsMockResponse) =>
    jest.fn().mockResolvedValue(response);
  const deleteBranchRuleSuccessHandler = jest.fn().mockResolvedValue(deleteBranchRuleMockResponse);
  const deleteBranchRuleErrorHandler = jest.fn().mockRejectedValue('error');

  const createComponent = async (
    glFeatures = { addBranchRule: true },
    mockResponse,
    mutationHandler = deleteBranchRuleSuccessHandler,
  ) => {
    fakeApollo = createMockApollo([
      [branchRulesQuery, branchProtectionsMockRequestHandler(mockResponse)],
      [deleteBranchRuleMutation, mutationHandler],
    ]);

    wrapper = shallowMountExtended(RuleView, {
      apolloProvider: fakeApollo,
      provide: { projectPath, protectedBranchesPath, branchRulesPath, glFeatures },
      stubs: {
        Protection,
        GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
      directives: { GlModal: createMockDirective('gl-modal') },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  const findBranchName = () => wrapper.findByTestId('branch');
  const findBranchTitle = () => wrapper.findByTestId('branch-title');
  const findBranchProtectionTitle = () => wrapper.findByText(I18N.protectBranchTitle);
  const findBranchProtections = () => wrapper.findAllComponents(Protection);
  const findForcePushIcon = () => wrapper.findByTestId('force-push-icon');
  const findForcePushTitle = (title) => wrapper.findByText(title);
  const findForcePushDescription = () => wrapper.findByText(I18N.forcePushDescription);
  const findApprovalsTitle = () => wrapper.findByText(I18N.approvalsTitle);
  const findpageTitle = () => wrapper.findByText(I18N.pageTitle);
  const findStatusChecksTitle = () => wrapper.findByText(I18N.statusChecksTitle);
  const findDeleteRuleButton = () => wrapper.findComponent(GlButton);
  const findDeleteRuleModal = () => wrapper.findComponent(GlModal);
  const findMatchingBranchesLink = () =>
    wrapper.findByText(
      sprintf(I18N.matchingBranchesLinkTitle, {
        total: matchingBranchesCount,
        subject: 'branches',
      }),
    );

  it('renders page title', () => {
    expect(findpageTitle().exists()).toBe(true);
  });

  it('renders delete rule button', () => {
    expect(findDeleteRuleButton().text()).toBe('Delete rule');
  });

  it('renders a modal with correct props/attributes', () => {
    expect(findDeleteRuleModal().props()).toMatchObject({
      modalId: DELETE_RULE_MODAL_ID,
      title: 'Delete branch rule?',
    });
    expect(findDeleteRuleModal().attributes('ok-title')).toBe('Delete branch rule');
  });

  it('renders correct modal id for the default action', () => {
    const binding = getBinding(findDeleteRuleButton().element, 'gl-modal');

    expect(binding.value).toBe(DELETE_RULE_MODAL_ID);
  });

  it('renders the correct modal content', () => {
    expect(findDeleteRuleModal().text()).toContain(
      'Are you sure you want to delete this branch rule? This action cannot be undone.',
    );
  });

  it('when delete button in the modal is clicked it makes a call to delete rule and redirects to overview page', async () => {
    findDeleteRuleModal().vm.$emit('ok');
    await waitForPromises();
    expect(deleteBranchRuleSuccessHandler).toHaveBeenCalledWith({
      input: { id: 'gid://gitlab/Projects/BranchRule/1' },
    });
    expect(util.visitUrl).toHaveBeenCalledWith('/-/settings/repository#branch_rules');
  });

  it('if error happens it shows an alert', async () => {
    await createComponent(
      { addBranchRule: true },
      branchProtectionsMockResponse,
      deleteBranchRuleErrorHandler,
    );
    findDeleteRuleModal().vm.$emit('ok');
    await nextTick();
    await waitForPromises();
    expect(deleteBranchRuleErrorHandler).toHaveBeenCalledWith({
      input: { id: 'gid://gitlab/Projects/BranchRule/1' },
    });
    expect(createAlert).toHaveBeenCalledWith({
      captureError: true,
      message: 'Something went wrong while deleting branch rule.',
    });
  });

  it('does not render delete rule button and modal when ff is disabled', () => {
    createComponent({ addBranchRule: false });
    expect(findDeleteRuleButton().exists()).toBe(false);
    expect(findDeleteRuleModal().exists()).toBe(false);
  });

  it('gets the branch param from url and renders it in the view', () => {
    expect(util.getParameterByName).toHaveBeenCalledWith('branch');
    expect(findBranchName().text()).toBe('main');
    expect(findBranchTitle().text()).toBe(I18N.branchNameOrPattern);
  });

  it('renders the correct label if all branches are targeted', async () => {
    jest.spyOn(util, 'getParameterByName').mockReturnValueOnce(ALL_BRANCHES_WILDCARD);
    await createComponent();

    expect(findBranchName().text()).toBe(I18N.allBranches);
    expect(findBranchTitle().text()).toBe(I18N.targetBranch);
  });

  it('renders the correct branch title', () => {
    expect(findBranchTitle().exists()).toBe(true);
  });

  it('renders matching branches link', () => {
    const mergeUrlParams = jest.spyOn(util, 'mergeUrlParams');
    const matchingBranchesLink = findMatchingBranchesLink();

    expect(mergeUrlParams).toHaveBeenCalledWith({ state: 'all', search: `^main$` }, '');
    expect(matchingBranchesLink.exists()).toBe(true);
    expect(matchingBranchesLink.attributes().href).toBe('/branches?state=all&search=%5Emain%24');
  });

  it('renders a branch protection title', () => {
    expect(findBranchProtectionTitle().exists()).toBe(true);
  });

  it('renders a branch protection component for push rules', () => {
    expect(findBranchProtections().at(0).props()).toMatchObject({
      header: sprintf(I18N.allowedToPushHeader, {
        total: 2,
      }),
      ...protectionMockProps,
    });
  });

  it('passes expected roles for push rules via props', () => {
    findBranchProtections()
      .at(0)
      .props()
      .roles.forEach((role, i) => {
        expect(role).toMatchObject({
          accessLevelDescription: roles[i].accessLevelDescription,
        });
      });
  });

  it.each`
    allowForcePush | iconName             | iconClass                  | title
    ${true}        | ${REQUIRED_ICON}     | ${REQUIRED_ICON_CLASS}     | ${I18N.allowForcePushTitle}
    ${false}       | ${NOT_REQUIRED_ICON} | ${NOT_REQUIRED_ICON_CLASS} | ${I18N.doesNotAllowForcePushTitle}
  `(
    'renders force push section with the correct icon, title and description',
    async ({ allowForcePush, iconName, iconClass, title }) => {
      const mockResponse = branchProtectionsMockResponse;
      mockResponse.data.project.branchRules.nodes[0].branchProtection.allowForcePush = allowForcePush;
      await createComponent(mockResponse);

      expect(findForcePushIcon().props('name')).toBe(iconName);
      expect(findForcePushIcon().attributes('class')).toBe(iconClass);
      expect(findForcePushTitle(title).exists()).toBe(true);
      expect(findForcePushDescription().exists()).toBe(true);
    },
  );

  it('renders a branch protection component for merge rules', () => {
    expect(findBranchProtections().at(1).props()).toMatchObject({
      header: sprintf(I18N.allowedToMergeHeader, {
        total: 2,
      }),
      ...protectionMockProps,
    });
  });

  it('passes expected roles form merge rules via props', () => {
    findBranchProtections()
      .at(1)
      .props()
      .roles.forEach((role, i) => {
        expect(role).toMatchObject({
          accessLevelDescription: roles[i].accessLevelDescription,
        });
      });
  });

  it('does not render a branch protection component for approvals', () => {
    expect(findApprovalsTitle().exists()).toBe(false);
  });

  it('does not render a branch protection component for status checks', () => {
    expect(findStatusChecksTitle().exists()).toBe(false);
  });
});
