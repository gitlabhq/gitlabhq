import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as util from '~/lib/utils/url_utility';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RuleView from '~/projects/settings/branch_rules/components/view/index.vue';
import Protection from '~/projects/settings/branch_rules/components/view/protection.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  REQUIRED_ICON,
  NOT_REQUIRED_ICON,
  REQUIRED_ICON_CLASS,
  NOT_REQUIRED_ICON_CLASS,
} from '~/projects/settings/branch_rules/components/view/constants';
import branchRulesQuery from 'ee_else_ce/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { sprintf } from '~/locale';
import {
  branchProtectionsMockResponse,
  matchingBranchesCount,
} from 'ee_else_ce_jest/projects/settings/branch_rules/components/view/mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockReturnValue('main'),
  mergeUrlParams: jest.fn().mockReturnValue('/branches?state=all&search=%5Emain%24'),
  joinPaths: jest.fn(),
}));

Vue.use(VueApollo);

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
  const branchProtectionsMockRequestHandler = (response = branchProtectionsMockResponse) =>
    jest.fn().mockResolvedValue(response);

  const createComponent = async (mockResponse) => {
    fakeApollo = createMockApollo([
      [branchRulesQuery, branchProtectionsMockRequestHandler(mockResponse)],
    ]);

    wrapper = shallowMountExtended(RuleView, {
      apolloProvider: fakeApollo,
      provide: { projectPath, protectedBranchesPath },
      stubs: { Protection },
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
