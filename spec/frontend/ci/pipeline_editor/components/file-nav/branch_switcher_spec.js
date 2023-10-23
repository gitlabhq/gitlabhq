import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BranchSwitcher from '~/ci/pipeline_editor/components/file_nav/branch_switcher.vue';
import { DEFAULT_FAILURE } from '~/ci/pipeline_editor/constants';
import getAvailableBranchesQuery from '~/ci/pipeline_editor/graphql/queries/available_branches.query.graphql';
import getCurrentBranch from '~/ci/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import getLastCommitBranch from '~/ci/pipeline_editor/graphql/queries/client/last_commit_branch.query.graphql';
import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';

import {
  generateMockProjectBranches,
  mockBranchPaginationLimit,
  mockDefaultBranch,
  mockEmptySearchBranches,
  mockProjectFullPath,
  mockSearchBranches,
  mockTotalBranches,
  mockTotalBranchResults,
  mockTotalSearchResults,
} from '../../mock_data';

describe('Pipeline editor branch switcher', () => {
  let wrapper;
  let mockApollo;
  let mockAvailableBranchQuery;

  Vue.use(VueApollo);

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [[getAvailableBranchesQuery, mockAvailableBranchQuery]];
    mockApollo = createMockApollo(handlers, resolvers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getCurrentBranch,
      data: {
        workBranches: {
          __typename: 'BranchList',
          current: {
            __typename: 'WorkBranch',
            name: mockDefaultBranch,
          },
        },
      },
    });

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getLastCommitBranch,
      data: {
        workBranches: {
          __typename: 'BranchList',
          lastCommit: {
            __typename: 'WorkBranch',
            name: '',
          },
        },
      },
    });

    wrapper = shallowMount(BranchSwitcher, {
      propsData: {
        ...props,
        paginationLimit: mockBranchPaginationLimit,
      },
      provide: {
        projectFullPath: mockProjectFullPath,
        totalBranches: mockTotalBranches,
      },
      apolloProvider: mockApollo,
      stubs: { GlCollapsibleListbox },
    });

    return waitForPromises();
  };

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGlListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const defaultBranchInDropdown = () => findGlListboxItems().at(0);

  const setAvailableBranchesMock = (availableBranches) => {
    mockAvailableBranchQuery.mockResolvedValue(availableBranches);
  };

  beforeEach(() => {
    mockAvailableBranchQuery = jest.fn();
  });

  const testErrorHandling = () => {
    expect(wrapper.emitted('showError')).toBeDefined();
    expect(wrapper.emitted('showError')[0]).toEqual([
      {
        reasons: ['Unable to fetch branch list for this project.'],
        type: DEFAULT_FAILURE,
      },
    ]);
  };

  describe('when querying for the first time', () => {
    beforeEach(() => {
      createComponent();
    });

    it('disables the dropdown', () => {
      expect(findGlCollapsibleListbox().props('disabled')).toBe(true);
    });
  });

  describe('after querying', () => {
    beforeEach(async () => {
      setAvailableBranchesMock(generateMockProjectBranches());
      await createComponent();
    });

    it('renders search box', () => {
      expect(findGlCollapsibleListbox().props().searchable).toBe(true);
    });

    it('renders list of branches', () => {
      expect(findGlCollapsibleListbox().exists()).toBe(true);
      expect(findGlListboxItems()).toHaveLength(mockTotalBranchResults);
    });

    it('renders current branch with a check mark', () => {
      expect(defaultBranchInDropdown().text()).toBe(mockDefaultBranch);
      expect(defaultBranchInDropdown().props('isSelected')).toBe(true);
    });

    it('does not render check mark for other branches', () => {
      const nonDefaultBranch = findGlListboxItems().at(1);

      expect(nonDefaultBranch.text()).not.toBe(mockDefaultBranch);
      expect(nonDefaultBranch.props('isSelected')).toBe(false);
    });
  });

  describe('on fetch error', () => {
    beforeEach(async () => {
      setAvailableBranchesMock(new Error());
      await createComponent();
    });

    it('does not render dropdown', () => {
      expect(findGlCollapsibleListbox().props('disabled')).toBe(true);
    });

    it('shows an error message', () => {
      testErrorHandling();
    });
  });

  describe('when switching branches', () => {
    beforeEach(async () => {
      jest.spyOn(window.history, 'pushState').mockImplementation(() => {});
      setAvailableBranchesMock(generateMockProjectBranches());
      await createComponent();
    });

    it('updates session history when selecting a different branch', async () => {
      const branch = findGlListboxItems().at(1);
      findGlCollapsibleListbox().vm.$emit('select', branch.text());
      await waitForPromises();

      expect(window.history.pushState).toHaveBeenCalled();
      expect(window.history.pushState.mock.calls[0][2]).toContain(`?branch_name=${branch.text()}`);
    });

    it('does not update session history when selecting current branch', async () => {
      const branch = findGlListboxItems().at(0);
      branch.vm.$emit('click');
      await waitForPromises();

      expect(branch.text()).toBe(mockDefaultBranch);
      expect(window.history.pushState).not.toHaveBeenCalled();
    });

    it('emits the `refetchContent` event when selecting a different branch', async () => {
      const branch = findGlListboxItems().at(1);

      expect(branch.text()).not.toBe(mockDefaultBranch);
      expect(wrapper.emitted('refetchContent')).toBeUndefined();

      findGlCollapsibleListbox().vm.$emit('select', branch.text());
      await waitForPromises();

      expect(wrapper.emitted('refetchContent')).toBeDefined();
      expect(wrapper.emitted('refetchContent')).toHaveLength(1);
    });

    it('does not emit the `refetchContent` event when selecting the current branch', async () => {
      const branch = findGlListboxItems().at(0);

      expect(branch.text()).toBe(mockDefaultBranch);
      expect(wrapper.emitted('refetchContent')).toBeUndefined();

      branch.vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('refetchContent')).toBeUndefined();
    });

    describe('with unsaved changes', () => {
      beforeEach(async () => {
        createComponent({ props: { hasUnsavedChanges: true } });
        await waitForPromises();
      });

      it('emits `select-branch` event and does not switch branch', () => {
        expect(wrapper.emitted('select-branch')).toBeUndefined();

        const branch = findGlListboxItems().at(1);
        findGlCollapsibleListbox().vm.$emit('select', branch.text());

        expect(wrapper.emitted('select-branch')).toEqual([[branch.text()]]);
        expect(wrapper.emitted('refetchContent')).toBeUndefined();
      });
    });
  });

  describe('when searching', () => {
    beforeEach(async () => {
      setAvailableBranchesMock(generateMockProjectBranches());
      await createComponent();
    });

    afterEach(() => {
      mockAvailableBranchQuery.mockClear();
    });

    it('shows error message on fetch error', async () => {
      mockAvailableBranchQuery.mockResolvedValue(new Error());

      findGlCollapsibleListbox().vm.$emit('search', 'te');
      await waitForPromises();

      testErrorHandling();
    });

    describe('with a search term', () => {
      beforeEach(() => {
        mockAvailableBranchQuery.mockResolvedValue(mockSearchBranches);
      });

      it('calls query with correct variables', async () => {
        findGlCollapsibleListbox().vm.$emit('search', 'te');

        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledWith({
          limit: mockTotalBranches, // fetch all branches
          offset: 0,
          projectFullPath: mockProjectFullPath,
          searchPattern: '*te*',
        });
      });

      it('fetches new list of branches', async () => {
        expect(findGlListboxItems()).toHaveLength(mockTotalBranchResults);

        findGlCollapsibleListbox().vm.$emit('search', 'te');
        await waitForPromises();

        expect(findGlListboxItems()).toHaveLength(mockTotalSearchResults);
      });

      it('does not hide dropdown when search result is empty', async () => {
        mockAvailableBranchQuery.mockResolvedValue(mockEmptySearchBranches);
        findGlCollapsibleListbox().vm.$emit('search', 'aaaa');
        await waitForPromises();

        expect(findGlCollapsibleListbox().exists()).toBe(true);
        expect(findGlListboxItems()).toHaveLength(0);
      });
    });

    describe('without a search term', () => {
      beforeEach(async () => {
        mockAvailableBranchQuery.mockResolvedValue(mockSearchBranches);
        findGlCollapsibleListbox().vm.$emit('search', 'te');
        await waitForPromises();

        mockAvailableBranchQuery.mockResolvedValue(generateMockProjectBranches());
      });

      it('calls query with correct variables', async () => {
        findGlCollapsibleListbox().vm.$emit('search', '');
        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledWith({
          limit: mockBranchPaginationLimit, // only fetch first n branches first
          offset: 0,
          projectFullPath: mockProjectFullPath,
          searchPattern: '*',
        });
      });

      it('fetches new list of branches', async () => {
        expect(findGlListboxItems()).toHaveLength(mockTotalSearchResults);

        findGlCollapsibleListbox().vm.$emit('search', '');
        await waitForPromises();

        expect(findGlListboxItems()).toHaveLength(mockTotalBranchResults);
      });
    });
  });

  describe('when scrolling to the bottom of the list', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    afterEach(() => {
      mockAvailableBranchQuery.mockClear();
    });

    describe('when search term exists', () => {
      it('does not fetch more branches', async () => {
        findGlCollapsibleListbox().vm.$emit('search', 'new');
        await waitForPromises();

        expect(mockAvailableBranchQuery).toHaveBeenCalledTimes(2);
        mockAvailableBranchQuery.mockClear();

        expect(mockAvailableBranchQuery).not.toHaveBeenCalled();
      });
    });
  });
});
