import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDropdown, GlSearchBoxByType, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchDropdown, {
  i18n,
} from '~/projects/settings/branch_rules/components/edit/branch_dropdown.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import branchesQuery from '~/projects/settings/branch_rules/queries/branches.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('Branch dropdown', () => {
  let wrapper;

  const projectPath = 'test/project';
  const value = 'main';
  const mockBranchNames = ['test 1', 'test 2'];

  const createComponent = async ({ branchNames = mockBranchNames, resolver } = {}) => {
    const mockResolver =
      resolver ||
      jest.fn().mockResolvedValue({
        data: { project: { id: '1', repository: { branchNames } } },
      });
    const apolloProvider = createMockApollo([[branchesQuery, mockResolver]]);

    wrapper = shallowMountExtended(BranchDropdown, {
      apolloProvider,
      propsData: { projectPath, value },
    });

    await waitForPromises();
  };

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllBranches = () => wrapper.findAllComponents(GlDropdownItem);
  const findNoDataMsg = () => wrapper.findByTestId('no-data');
  const findGlSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findWildcardButton = () => wrapper.findByTestId('create-wildcard-button');
  const findHelpText = () => wrapper.findComponent(GlSprintf);
  const setSearchTerm = (searchTerm) => findGlSearchBoxByType().vm.$emit('input', searchTerm);

  beforeEach(() => createComponent());

  it('renders a GlDropdown component with the correct props', () => {
    expect(findGlDropdown().props()).toMatchObject({ text: value });
  });

  it('renders GlDropdownItem components for each branch', () => {
    expect(findAllBranches().length).toBe(mockBranchNames.length);

    mockBranchNames.forEach((branchName, index) =>
      expect(findAllBranches().at(index).text()).toBe(branchName),
    );
  });

  it('emits `select` with the branch name when a branch is clicked', () => {
    findAllBranches().at(0).vm.$emit('click');
    expect(wrapper.emitted('input')).toEqual([[mockBranchNames[0]]]);
  });

  describe('branch searching', () => {
    it('displays a message if no branches can be found', async () => {
      await createComponent({ branchNames: [] });

      expect(findNoDataMsg().text()).toBe(i18n.noMatch);
    });

    it('displays a loading state while search request is in flight', async () => {
      setSearchTerm('test');
      await nextTick();

      expect(findGlSearchBoxByType().props()).toMatchObject({ isLoading: true });
    });

    it('renders a wildcard button', async () => {
      const searchTerm = 'test-*';
      setSearchTerm(searchTerm);
      await nextTick();

      expect(findWildcardButton().exists()).toBe(true);
      findWildcardButton().vm.$emit('click');
      expect(wrapper.emitted('createWildcard')).toEqual([[searchTerm]]);
    });

    it('renders help text', () => {
      expect(findHelpText().attributes('message')).toBe(i18n.branchHelpText);
    });
  });

  it('displays an error message if fetch failed', async () => {
    const error = new Error('an error occurred');
    const resolver = jest.fn().mockRejectedValueOnce(error);
    await createComponent({ resolver });

    expect(createAlert).toHaveBeenCalledWith({
      message: i18n.fetchBranchesError,
      captureError: true,
      error,
    });
  });
});
