import {
  GlDropdown,
  GlDropdownItem,
  GlInfiniteScroll,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BranchSwitcher from '~/pipeline_editor/components/file_nav/branch_switcher.vue';
import { DEFAULT_FAILURE } from '~/pipeline_editor/constants';
import getAvailableBranchesQuery from '~/pipeline_editor/graphql/queries/available_branches.graphql';
import {
  mockBranchPaginationLimit,
  mockDefaultBranch,
  mockEmptySearchBranches,
  mockProjectBranches,
  mockProjectFullPath,
  mockSearchBranches,
  mockTotalBranches,
  mockTotalBranchResults,
  mockTotalSearchResults,
  mockNewBranch,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Pipeline editor branch switcher', () => {
  let wrapper;
  let mockApollo;
  let mockAvailableBranchQuery;
  let mockCurrentBranchQuery;
  let mockLastCommitBranchQuery;

  const createComponent = (
    { currentBranch, isQueryLoading, mountFn, options } = {
      currentBranch: mockDefaultBranch,
      isQueryLoading: false,
      mountFn: shallowMount,
      options: {},
    },
  ) => {
    wrapper = mountFn(BranchSwitcher, {
      propsData: {
        paginationLimit: mockBranchPaginationLimit,
      },
      provide: {
        projectFullPath: mockProjectFullPath,
        totalBranches: mockTotalBranches,
      },
      mocks: {
        $apollo: {
          queries: {
            availableBranches: {
              loading: isQueryLoading,
            },
          },
        },
      },
      data() {
        return {
          availableBranches: ['main'],
          currentBranch,
        };
      },
      ...options,
    });
  };

  const createComponentWithApollo = (mountFn = shallowMount) => {
    const handlers = [[getAvailableBranchesQuery, mockAvailableBranchQuery]];
    const resolvers = {
      Query: {
        currentBranch() {
          return mockCurrentBranchQuery();
        },
        lastCommitBranch() {
          return mockLastCommitBranchQuery();
        },
      },
    };
    mockApollo = createMockApollo(handlers, resolvers);

    createComponent({
      mountFn,
      options: {
        localVue,
        apolloProvider: mockApollo,
        mocks: {},
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findInfiniteScroll = () => wrapper.findComponent(GlInfiniteScroll);
  const defaultBranchInDropdown = () => findDropdownItems().at(0);

  const setMockResolvedValues = ({ availableBranches, currentBranch, lastCommitBranch }) => {
    if (availableBranches) {
      mockAvailableBranchQuery.mockResolvedValue(availableBranches);
    }

    if (currentBranch) {
      mockCurrentBranchQuery.mockResolvedValue(currentBranch);
    }

    mockLastCommitBranchQuery.mockResolvedValue(lastCommitBranch || '');
  };

  beforeEach(() => {
    mockAvailableBranchQuery = jest.fn();
    mockCurrentBranchQuery = jest.fn();
    mockLastCommitBranchQuery = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const testErrorHandling = () => {
    expect(wrapper.emitted('showError')).toBeDefined();
    expect(wrapper.emitted('showError')[0]).toEqual([
      {
        reasons: [wrapper.vm.$options.i18n.fetchError],
        type: DEFAULT_FAILURE,
      },
    ]);
  };

  describe('when querying for the first time', () => {
    beforeEach(() => {
      createComponentWithApollo();
    });

    it('does not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });
  });

  describe('after querying', () => {
    beforeEach(async () => {
      setMockResolvedValues({
        availableBranches: mockProjectBranches,
        currentBranch: mockDefaultBranch,
      });
      createComponentWithApollo(mount);
      await waitForPromises();
    });

    it('renders search box', () => {
      expect(findSearchBox().exists()).toBe(true);
    });

    it('renders list of branches', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findDropdownItems()).toHaveLength(mockTotalBranchResults);
    });

    it('renders current branch with a check mark', () => {
      expect(defaultBranchInDropdown().text()).toBe(mockDefaultBranch);
      expect(defaultBranchInDropdown().props('isChecked')).toBe(true);
    });

    it('does not render check mark for other branches', () => {
      const nonDefaultBranch = findDropdownItems().at(1);

      expect(nonDefaultBranch.text()).not.toBe(mockDefaultBranch);
      expect(nonDefaultBranch.props('isChecked')).toBe(false);
    });
  });

  describe('on fetch error', () => {
    beforeEach(async () => {
      setMockResolvedValues({
        availableBranches: new Error(),
        currentBranch: mockDefaultBranch,
      });
      createComponentWithApollo();
      await waitForPromises();
    });

    it('does not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });

    it('shows an error message', () => {
      testErrorHandling();
    });
  });

  describe('when switching branches', () => {
    beforeEach(async () => {
      jest.spyOn(window.history, 'pushState').mockImplementation(() => {});
      setMockResolvedValues({
        availableBranches: mockProjectBranches,
        currentBranch: mockDefaultBranch,
      });
      createComponentWithApollo(mount);
      await waitForPromises();
    });

    it('updates session history when selecting a different branch', async () => {
      const branch = findDropdownItems().at(1);
      branch.vm.$emit('click');
      await waitForPromises();

      expect(window.history.pushState).toHaveBeenCalled();
      expect(window.history.pushState.mock.calls[0][2]).toContain(`?branch_name=${branch.text()}`);
    });

    it('does not update session history when selecting current branch', async () => {
      const branch = findDropdownItems().at(0);
      branch.vm.$emit('click');
      await waitForPromises();

      expect(branch.text()).toBe(mockDefaultBranch);
      expect(window.history.pushState).not.toHaveBeenCalled();
    });

    it('emits the refetchContent event when selecting a different branch', async () => {
      const branch = findDropdownItems().at(1);

      expect(branch.text()).not.toBe(mockDefaultBranch);
      expect(wrapper.emitted('refetchContent')).toBeUndefined();

      branch.vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('refetchContent')).toBeDefined();
      expect(wrapper.emitted('refetchContent')).toHaveLength(1);
    });

    it('does not emit the refetchContent event when selecting the current branch', async () => {
      const branch = findDropdownItems().at(0);

      expect(branch.text()).toBe(mockDefaultBranch);
      expect(wrapper.emitted('refetchContent')).toBeUndefined();

      branch.vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('refetchContent')).toBeUndefined();
    });

    it('emits the updateCommitSha event when selecting a different branch', async () => {
      expect(wrapper.emitted('updateCommitSha')).toBeUndefined();

      const branch = findDropdownItems().at(1);
      branch.vm.$emit('click');

      expect(wrapper.emitted('updateCommitSha')).toHaveLength(1);
    });
  });

  describe('when searching', () => {
    beforeEach(async () => {
      setMockResolvedValues({
        availableBranches: mockProjectBranches,
        currentBranch: mockDefaultBranch,
      });
      createComponentWithApollo(mount);
      await waitForPromises();
    });

    afterEach(() => {
      mockAvailableBranchQuery.mockClear();
    });

    it('shows error message on fetch error', async () => {
      mockAvailableBranchQuery.mockResolvedValue(new Error());

      findSearchBox().vm.$emit('input', 'te');
      await waitForPromises();

      testErrorHandling();
    });

    describe('with a search term', () => {
      beforeEach(async () => {
        mockAvailableBranchQuery.mockResolvedValue(mockSearchBranches);
      });

      it('calls query with correct variables', async () => {
        findSearchBox().vm.$emit('input', 'te');
        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledWith({
          limit: mockTotalBranches, // fetch all branches
          offset: 0,
          projectFullPath: mockProjectFullPath,
          searchPattern: '*te*',
        });
      });

      it('fetches new list of branches', async () => {
        expect(findDropdownItems()).toHaveLength(mockTotalBranchResults);

        findSearchBox().vm.$emit('input', 'te');
        await waitForPromises();

        expect(findDropdownItems()).toHaveLength(mockTotalSearchResults);
      });

      it('does not hide dropdown when search result is empty', async () => {
        mockAvailableBranchQuery.mockResolvedValue(mockEmptySearchBranches);
        findSearchBox().vm.$emit('input', 'aaaaa');
        await waitForPromises();

        expect(findDropdown().exists()).toBe(true);
        expect(findDropdownItems()).toHaveLength(0);
      });
    });

    describe('without a search term', () => {
      beforeEach(async () => {
        mockAvailableBranchQuery.mockResolvedValue(mockSearchBranches);
        findSearchBox().vm.$emit('input', 'te');
        await waitForPromises();

        mockAvailableBranchQuery.mockResolvedValue(mockProjectBranches);
      });

      it('calls query with correct variables', async () => {
        findSearchBox().vm.$emit('input', '');
        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledWith({
          limit: mockBranchPaginationLimit, // only fetch first n branches first
          offset: 0,
          projectFullPath: mockProjectFullPath,
          searchPattern: '*',
        });
      });

      it('fetches new list of branches', async () => {
        expect(findDropdownItems()).toHaveLength(mockTotalSearchResults);

        findSearchBox().vm.$emit('input', '');
        await waitForPromises();

        expect(findDropdownItems()).toHaveLength(mockTotalBranchResults);
      });
    });
  });

  describe('loading icon', () => {
    test.each`
      isQueryLoading | isRendered
      ${true}        | ${true}
      ${false}       | ${false}
    `('checks if query is loading before rendering', ({ isQueryLoading, isRendered }) => {
      createComponent({ isQueryLoading, mountFn: mount });

      expect(findLoadingIcon().exists()).toBe(isRendered);
    });
  });

  describe('when scrolling to the bottom of the list', () => {
    beforeEach(async () => {
      setMockResolvedValues({
        availableBranches: mockProjectBranches,
        currentBranch: mockDefaultBranch,
      });
      createComponentWithApollo();
      await waitForPromises();
    });

    afterEach(() => {
      mockAvailableBranchQuery.mockClear();
    });

    describe('when search term is empty', () => {
      it('fetches more branches', async () => {
        expect(mockAvailableBranchQuery).toHaveBeenCalledTimes(1);

        findInfiniteScroll().vm.$emit('bottomReached');
        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledTimes(2);
      });

      it('calls the query with the correct variables', async () => {
        findInfiniteScroll().vm.$emit('bottomReached');
        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledWith({
          limit: mockBranchPaginationLimit,
          offset: mockBranchPaginationLimit, // offset changed
          projectFullPath: mockProjectFullPath,
          searchPattern: '*',
        });
      });

      it('shows error message on fetch error', async () => {
        mockAvailableBranchQuery.mockResolvedValue(new Error());

        findInfiniteScroll().vm.$emit('bottomReached');
        await waitForPromises();

        testErrorHandling();
      });
    });

    describe('when search term exists', () => {
      it('does not fetch more branches', async () => {
        findSearchBox().vm.$emit('input', 'te');
        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledTimes(2);
        mockAvailableBranchQuery.mockClear();

        findInfiniteScroll().vm.$emit('bottomReached');
        await waitForPromises();

        expect(mockAvailableBranchQuery).not.toHaveBeenCalled();
      });
    });
  });

  describe('when committing a new branch', () => {
    const createNewBranch = async () => {
      setMockResolvedValues({
        currentBranch: mockNewBranch,
        lastCommitBranch: mockNewBranch,
      });
      await wrapper.vm.$apollo.queries.currentBranch.refetch();
      await wrapper.vm.$apollo.queries.lastCommitBranch.refetch();
    };

    beforeEach(async () => {
      setMockResolvedValues({
        availableBranches: mockProjectBranches,
        currentBranch: mockDefaultBranch,
      });
      createComponentWithApollo(mount);
      await waitForPromises();
      await createNewBranch();
    });

    it('sets new branch as current branch', () => {
      expect(defaultBranchInDropdown().text()).toBe(mockNewBranch);
      expect(defaultBranchInDropdown().props('isChecked')).toBe(true);
    });

    it('adds new branch to branch switcher', () => {
      expect(defaultBranchInDropdown().text()).toBe(mockNewBranch);
      expect(findDropdownItems()).toHaveLength(mockTotalBranchResults + 1);
    });
  });
});
