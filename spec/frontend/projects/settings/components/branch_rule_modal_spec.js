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

  it('renders updated help text', () => {
    expect(findHelpText().text()).toMatchInterpolatedText(
      `Select an existing branch, create a branch rule, or use wildcards such as *-stable or production/*. Branch names are case-sensitive. Learn more.`,
    );
  });

  it('renders help link', () => {
    expect(findHelpLink().attributes('href')).toBe(
      '/help/user/project/repository/branches/protected#use-wildcard-rules',
    );
  });

  it('queries protectable branches', async () => {
    await nextTick();
    expect(protectableBranchesQuerySuccessHandler).toHaveBeenCalledWith({
      projectPath: 'test/testing',
    });
  });

  it('renders listbox with branch names', async () => {
    await waitForPromises();
    expect(findBranchRuleListbox().exists()).toBe(true);
    expect(findBranchRuleListbox().props('items')).toHaveLength(3);
    expect(findBranchRuleListbox().props('toggleText')).toBe('Select branch or create rule');
  });

  describe('search functionality', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('filters existing branches based on search query', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'main');
      await nextTick();

      const existingBranches = listbox
        .props('items')
        .filter((item) => !item.isWildcard && !item.isBranchName && !item.isNoResults);
      expect(existingBranches).toHaveLength(1);
      expect(existingBranches[0].text).toBe('main');
    });

    it('shows "No branch rules found" when no existing branches match', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'nonexistent');
      await nextTick();

      const items = listbox.props('items');
      const noResultsItem = items.find((item) => item.isNoResults);
      expect(noResultsItem).toBeDefined();
      expect(noResultsItem.text).toBe('No branch rules found');
      expect(noResultsItem.disabled).toBe(true);
    });

    it('shows wildcard creation option when search contains asterisk', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'feature-*');
      await nextTick();

      const items = listbox.props('items');
      const wildcardItem = items.find((item) => item.isWildcard);
      expect(wildcardItem).toBeDefined();
      expect(wildcardItem.text).toBe('Create wildcard');
      expect(wildcardItem.value).toBe('feature-*');
    });

    it('shows branch rule creation option when search does not contain asterisk', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'new-feature');
      await nextTick();

      const items = listbox.props('items');
      const branchNameItem = items.find((item) => item.isBranchName);
      expect(branchNameItem).toBeDefined();
      expect(branchNameItem.text).toBe('Create branch rule');
      expect(branchNameItem.value).toBe('new-feature');
    });

    it('shows both "No branch rules found" and creation options when no matches', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'nonexistent-branch');
      await nextTick();

      const items = listbox.props('items');

      // Should have "No branch rules found" message
      const noResultsItem = items.find((item) => item.isNoResults);
      expect(noResultsItem).toBeDefined();

      // Should have branch creation option
      const branchNameItem = items.find((item) => item.isBranchName);
      expect(branchNameItem).toBeDefined();

      // Should not have wildcard option (no asterisk)
      const wildcardItem = items.find((item) => item.isWildcard);
      expect(wildcardItem).toBeUndefined();
    });

    it('shows both "No branch rules found" and wildcard creation for wildcard search', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'nonexistent-*');
      await nextTick();

      const items = listbox.props('items');

      // Should have "No branch rules found" message
      const noResultsItem = items.find((item) => item.isNoResults);
      expect(noResultsItem).toBeDefined();

      // Should have wildcard creation option
      const wildcardItem = items.find((item) => item.isWildcard);
      expect(wildcardItem).toBeDefined();

      // Should not have branch name option (contains asterisk)
      const branchNameItem = items.find((item) => item.isBranchName);
      expect(branchNameItem).toBeUndefined();
    });

    it('does not show creation options when search matches existing branch', async () => {
      const listbox = findBranchRuleListbox();

      // Assuming 'main' exists in mock data
      await listbox.vm.$emit('search', 'main');
      await nextTick();

      const items = listbox.props('items');

      // Should not have creation options when exact match exists
      const wildcardItem = items.find((item) => item.isWildcard);
      const branchNameItem = items.find((item) => item.isBranchName);
      const noResultsItem = items.find((item) => item.isNoResults);

      expect(wildcardItem).toBeUndefined();
      expect(branchNameItem).toBeUndefined();
      expect(noResultsItem).toBeUndefined();
    });
  });

  describe('selection handling', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('allows selection of existing branches', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('select', 'main');
      await nextTick();

      expect(listbox.props('selected')).toBe('main');
    });

    it('allows selection of wildcard rules', async () => {
      const listbox = findBranchRuleListbox();

      // Set up wildcard search first
      await listbox.vm.$emit('search', 'feature-*');
      await nextTick();

      await listbox.vm.$emit('select', 'feature-*');
      await nextTick();

      expect(listbox.props('selected')).toBe('feature-*');
    });

    it('allows selection of branch name rules', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'new-branch');
      await nextTick();

      await listbox.vm.$emit('select', 'new-branch');
      await nextTick();

      expect(listbox.props('selected')).toBe('new-branch');
    });

    it('prevents selection of "No branch rules found" item', async () => {
      const listbox = findBranchRuleListbox();

      await listbox.vm.$emit('search', 'nonexistent');
      await nextTick();

      await listbox.vm.$emit('select', '');
      await nextTick();

      expect(listbox.props('selected')).toBe('');
    });
  });

  describe('list item rendering', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders existing branch items normally', async () => {
      const listbox = findBranchRuleListbox();
      await listbox.vm.$emit('search', 'main');
      await nextTick();

      const items = listbox.props('items');
      const existingBranch = items.find((item) => item.text === 'main');
      expect(existingBranch).toBeDefined();
      expect(existingBranch.isWildcard).toBeUndefined();
      expect(existingBranch.isBranchName).toBeUndefined();
      expect(existingBranch.isNoResults).toBeUndefined();
    });

    it('renders wildcard creation items with search query code block', async () => {
      const listbox = findBranchRuleListbox();
      await listbox.vm.$emit('search', 'feature-*');
      await nextTick();

      const items = listbox.props('items');
      const wildcardItem = items.find((item) => item.isWildcard);
      expect(wildcardItem.text).toBe('Create wildcard');
      expect(wildcardItem.value).toBe('feature-*');
      expect(wildcardItem.isWildcard).toBe(true);
    });

    it('renders branch rule creation items with search query code block', async () => {
      const listbox = findBranchRuleListbox();
      await listbox.vm.$emit('search', 'new-branch');
      await nextTick();

      const items = listbox.props('items');
      const branchNameItem = items.find((item) => item.isBranchName);
      expect(branchNameItem.text).toBe('Create branch rule');
      expect(branchNameItem.value).toBe('new-branch');
      expect(branchNameItem.isBranchName).toBe(true);
    });

    it('renders no results item as disabled', async () => {
      const listbox = findBranchRuleListbox();
      await listbox.vm.$emit('search', 'nonexistent');
      await nextTick();

      const items = listbox.props('items');
      const noResultsItem = items.find((item) => item.isNoResults);
      expect(noResultsItem.text).toBe('No branch rules found');
      expect(noResultsItem.disabled).toBe(true);
      expect(noResultsItem.value).toBe('');
    });
  });
});
