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
import getAvailableBranches from '~/pipeline_editor/graphql/queries/available_branches.graphql';
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
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Pipeline editor branch switcher', () => {
  let wrapper;
  let mockApollo;
  let mockAvailableBranchQuery;

  const createComponent = (
    { isQueryLoading, mountFn, options } = {
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
          branches: ['main'],
          currentBranch: mockDefaultBranch,
        };
      },
      ...options,
    });
  };

  const createComponentWithApollo = (mountFn = shallowMount) => {
    const handlers = [[getAvailableBranches, mockAvailableBranchQuery]];
    mockApollo = createMockApollo(handlers);

    createComponent({
      mountFn,
      options: {
        localVue,
        apolloProvider: mockApollo,
        mocks: {},
        data() {
          return {
            currentBranch: mockDefaultBranch,
          };
        },
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findInfiniteScroll = () => wrapper.findComponent(GlInfiniteScroll);

  beforeEach(() => {
    mockAvailableBranchQuery = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

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
      mockAvailableBranchQuery.mockResolvedValue(mockProjectBranches);
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
      const defaultBranchInDropdown = findDropdownItems().at(0);

      expect(defaultBranchInDropdown.text()).toBe(mockDefaultBranch);
      expect(defaultBranchInDropdown.props('isChecked')).toBe(true);
    });

    it('does not render check mark for other branches', () => {
      const nonDefaultBranch = findDropdownItems().at(1);

      expect(nonDefaultBranch.text()).not.toBe(mockDefaultBranch);
      expect(nonDefaultBranch.props('isChecked')).toBe(false);
    });
  });

  describe('on fetch error', () => {
    beforeEach(async () => {
      mockAvailableBranchQuery.mockResolvedValue(new Error());
      createComponentWithApollo();
      await waitForPromises();
    });

    it('does not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });

    it('shows an error message', () => {
      expect(wrapper.emitted('showError')).toBeDefined();
      expect(wrapper.emitted('showError')[0]).toEqual([
        {
          reasons: [wrapper.vm.$options.i18n.fetchError],
          type: DEFAULT_FAILURE,
        },
      ]);
    });
  });

  describe('when switching branches', () => {
    beforeEach(async () => {
      jest.spyOn(window.history, 'pushState').mockImplementation(() => {});
      mockAvailableBranchQuery.mockResolvedValue(mockProjectBranches);
      createComponentWithApollo(mount);
      await waitForPromises();
    });

    it('updates session history when selecting a different branch', async () => {
      const branch = findDropdownItems().at(1);
      await branch.vm.$emit('click');

      expect(window.history.pushState).toHaveBeenCalled();
      expect(window.history.pushState.mock.calls[0][2]).toContain(`?branch_name=${branch.text()}`);
    });

    it('does not update session history when selecting current branch', async () => {
      const branch = findDropdownItems().at(0);
      await branch.vm.$emit('click');

      expect(branch.text()).toBe(mockDefaultBranch);
      expect(window.history.pushState).not.toHaveBeenCalled();
    });

    it('emits the refetchContent event when selecting a different branch', async () => {
      const branch = findDropdownItems().at(1);

      expect(branch.text()).not.toBe(mockDefaultBranch);
      expect(wrapper.emitted('refetchContent')).toBeUndefined();

      await branch.vm.$emit('click');

      expect(wrapper.emitted('refetchContent')).toBeDefined();
      expect(wrapper.emitted('refetchContent')).toHaveLength(1);
    });

    it('does not emit the refetchContent event when selecting the current branch', async () => {
      const branch = findDropdownItems().at(0);

      expect(branch.text()).toBe(mockDefaultBranch);
      expect(wrapper.emitted('refetchContent')).toBeUndefined();

      await branch.vm.$emit('click');

      expect(wrapper.emitted('refetchContent')).toBeUndefined();
    });
  });

  describe('when searching', () => {
    beforeEach(async () => {
      mockAvailableBranchQuery.mockResolvedValue(mockProjectBranches);
      createComponentWithApollo(mount);
      await waitForPromises();

      mockAvailableBranchQuery.mockResolvedValue(mockSearchBranches);
    });

    describe('with a search term', () => {
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
      mockAvailableBranchQuery.mockResolvedValue(mockProjectBranches);
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
});
