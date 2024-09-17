import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlSprintf, GlLink } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import getProtectableBranches from '~/projects/settings/graphql/queries/protectable_branches.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchRuleModal from '~/projects/settings/components/branch_rule_modal.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { protectableBranchesMockResponse } from '../branch_rules/components/view/mock_data';

Vue.use(VueApollo);

describe('BranchRuleModal', () => {
  const protectableBranchesQuerySuccessHandler = jest
    .fn()
    .mockResolvedValue(protectableBranchesMockResponse);
  const projectPath = 'test/testing';
  let wrapper;
  let fakeApollo;
  const createComponent = async ({
    queryHandler = protectableBranchesQuerySuccessHandler,
  } = {}) => {
    fakeApollo = createMockApollo([[getProtectableBranches, queryHandler]]);

    wrapper = shallowMountExtended(BranchRuleModal, {
      apolloProvider: fakeApollo,
      provide: { projectPath },
      propsData: {
        id: 'test-id',
        title: 'Test Title',
        actionPrimaryText: 'Primary Action',
      },
      stubs: {
        GlSprintf,
      },
    });

    await waitForPromises();
  };

  beforeEach(() => {
    createComponent();
  });

  const findBranchRuleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findHelpText = () => wrapper.findByTestId('help-text');
  const findHelpLink = () => wrapper.findComponent(GlLink);

  it('renders dropdown with correct initial data', () => {
    expect(findBranchRuleListbox().props()).toMatchObject({
      items: [],
      selected: '',
    });
  });

  it('renders help text', () => {
    expect(findHelpText().text()).toMatchInterpolatedText(
      `Wildcards such as *-stable or production/ are supported`,
    );
  });

  it('renders help link', () => {
    expect(findHelpLink().attributes('href')).toBe(
      '/help/user/project/repository/branches/protected#protect-multiple-branches-with-wildcard-rules',
    );
  });

  it('queries protectable branches', async () => {
    await nextTick();
    expect(protectableBranchesQuerySuccessHandler).toHaveBeenCalledWith({
      projectPath: 'test/testing',
    });
  });

  it('renders listbox with branch names', async () => {
    await nextTick();
    expect(findBranchRuleListbox().exists()).toBe(true);
    expect(findBranchRuleListbox().props('items')).toHaveLength(3);
    expect(findBranchRuleListbox().props('toggleText')).toBe('Select Branch or create wildcard');
  });
});
