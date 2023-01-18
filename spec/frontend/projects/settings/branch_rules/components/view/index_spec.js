import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as util from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RuleView from '~/projects/settings/branch_rules/components/view/index.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
} from '~/projects/settings/branch_rules/components/view/constants';
import Protection from '~/projects/settings/branch_rules/components/view/protection.vue';
import branchRulesQuery from '~/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { sprintf } from '~/locale';
import {
  branchProtectionsMockResponse,
  approvalRulesMock,
  statusChecksRulesMock,
  matchingBranchesCount,
} from './mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockReturnValue('main'),
  mergeUrlParams: jest.fn().mockReturnValue('/branches?state=all&search=main'),
  joinPaths: jest.fn(),
}));

Vue.use(VueApollo);

const protectionMockProps = {
  headerLinkHref: 'protected/branches',
  headerLinkTitle: 'Manage in protected branches',
  roles: [{ accessLevelDescription: 'Maintainers' }],
  users: [{ avatarUrl: 'test.com/user.png', name: 'peter', webUrl: 'test.com' }],
};

describe('View branch rules', () => {
  let wrapper;
  let fakeApollo;
  const projectPath = 'test/testing';
  const protectedBranchesPath = 'protected/branches';
  const approvalRulesPath = 'approval/rules';
  const statusChecksPath = 'status/checks';
  const branchProtectionsMockRequestHandler = jest
    .fn()
    .mockResolvedValue(branchProtectionsMockResponse);

  const createComponent = async () => {
    fakeApollo = createMockApollo([[branchRulesQuery, branchProtectionsMockRequestHandler]]);

    wrapper = shallowMountExtended(RuleView, {
      apolloProvider: fakeApollo,
      provide: { projectPath, protectedBranchesPath, approvalRulesPath, statusChecksPath },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  const findBranchName = () => wrapper.findByTestId('branch');
  const findBranchTitle = () => wrapper.findByTestId('branch-title');
  const findBranchProtectionTitle = () => wrapper.findByText(I18N.protectBranchTitle);
  const findBranchProtections = () => wrapper.findAllComponents(Protection);
  const findForcePushTitle = () => wrapper.findByText(I18N.allowForcePushDescription);
  const findApprovalsTitle = () => wrapper.findByText(I18N.approvalsTitle);
  const findStatusChecksTitle = () => wrapper.findByText(I18N.statusChecksTitle);
  const findMatchingBranchesLink = () =>
    wrapper.findByText(
      sprintf(I18N.matchingBranchesLinkTitle, {
        total: matchingBranchesCount,
        subject: 'branches',
      }),
    );

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
    jest.restoreAllMocks();
  });

  it('renders the correct branch title', () => {
    expect(findBranchTitle().exists()).toBe(true);
  });

  it('renders matching branches link', () => {
    const matchingBranchesLink = findMatchingBranchesLink();
    expect(matchingBranchesLink.exists()).toBe(true);
    expect(matchingBranchesLink.attributes().href).toBe('/branches?state=all&search=main');
  });

  it('renders a branch protection title', () => {
    expect(findBranchProtectionTitle().exists()).toBe(true);
  });

  it('renders a branch protection component for push rules', () => {
    expect(findBranchProtections().at(0).props()).toMatchObject({
      header: sprintf(I18N.allowedToPushHeader, { total: 2 }),
      ...protectionMockProps,
    });
  });

  it('renders force push protection', () => {
    expect(findForcePushTitle().exists()).toBe(true);
  });

  it('renders a branch protection component for merge rules', () => {
    expect(findBranchProtections().at(1).props()).toMatchObject({
      header: sprintf(I18N.allowedToMergeHeader, { total: 2 }),
      ...protectionMockProps,
    });
  });

  it('renders a branch protection component for approvals', () => {
    expect(findApprovalsTitle().exists()).toBe(true);

    expect(findBranchProtections().at(2).props()).toMatchObject({
      header: sprintf(I18N.approvalsHeader, { total: 3 }),
      headerLinkHref: approvalRulesPath,
      headerLinkTitle: I18N.manageApprovalsLinkTitle,
      approvals: approvalRulesMock,
    });
  });

  it('renders a branch protection component for status checks', () => {
    expect(findStatusChecksTitle().exists()).toBe(true);

    expect(findBranchProtections().at(3).props()).toMatchObject({
      header: sprintf(I18N.statusChecksHeader, { total: 2 }),
      headerLinkHref: statusChecksPath,
      headerLinkTitle: I18N.statusChecksLinkTitle,
      statusChecks: statusChecksRulesMock,
    });
  });
});
