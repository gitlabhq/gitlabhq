import { GlAlert, GlLoadingIcon, GlSearchBoxByType, GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { fetchGroups } from '~/jira_connect/subscriptions/api';
import GroupsList from '~/jira_connect/subscriptions/components/groups_list.vue';
import GroupsListItem from '~/jira_connect/subscriptions/components/groups_list_item.vue';
import { DEFAULT_GROUPS_PER_PAGE } from '~/jira_connect/subscriptions/constants';
import { mockGroup1, mockGroup2 } from '../mock_data';

const createMockGroup = (groupId) => {
  return {
    ...mockGroup1,
    id: groupId,
  };
};

const createMockGroups = (count) => {
  return [...new Array(count)].map((_, idx) => createMockGroup(idx));
};

jest.mock('~/jira_connect/subscriptions/api', () => {
  return {
    fetchGroups: jest.fn(),
  };
});

const mockGroupsPath = '/groups';

describe('GroupsList', () => {
  let wrapper;

  const mockEmptyResponse = { data: [] };

  const createComponent = (options = {}) => {
    wrapper = extendedWrapper(
      shallowMount(GroupsList, {
        provide: {
          groupsPath: mockGroupsPath,
        },
        ...options,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAllItems = () => wrapper.findAll(GroupsListItem);
  const findFirstItem = () => findAllItems().at(0);
  const findSecondItem = () => findAllItems().at(1);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findGroupsList = () => wrapper.findByTestId('groups-list');
  const findPagination = () => wrapper.findComponent(GlPagination);

  describe('when groups are loading', () => {
    it('renders loading icon', async () => {
      fetchGroups.mockReturnValue(new Promise(() => {}));
      createComponent();

      await wrapper.vm.$nextTick();

      expect(findGlLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when groups fetch fails', () => {
    it('renders error message', async () => {
      fetchGroups.mockRejectedValue();
      createComponent();

      await waitForPromises();

      expect(findGlLoadingIcon().exists()).toBe(false);
      expect(findGlAlert().exists()).toBe(true);
      expect(findGlAlert().text()).toBe('Failed to load namespaces. Please try again.');
    });
  });

  describe('with no groups returned', () => {
    it('renders empty state', async () => {
      fetchGroups.mockResolvedValue(mockEmptyResponse);
      createComponent();

      await waitForPromises();

      expect(findGlLoadingIcon().exists()).toBe(false);
      expect(wrapper.text()).toContain('No available namespaces');
    });
  });

  describe('with groups returned', () => {
    beforeEach(async () => {
      fetchGroups.mockResolvedValue({
        headers: { 'X-PAGE': 1, 'X-TOTAL': 2 },
        data: [mockGroup1, mockGroup2],
      });
      createComponent();

      await waitForPromises();
    });

    it('renders groups list', () => {
      expect(findAllItems()).toHaveLength(2);
      expect(findFirstItem().props('group')).toBe(mockGroup1);
      expect(findSecondItem().props('group')).toBe(mockGroup2);
    });

    it('sets GroupListItem `disabled` prop to `false`', () => {
      findAllItems().wrappers.forEach((groupListItem) => {
        expect(groupListItem.props('disabled')).toBe(false);
      });
    });

    it('does not set opacity of the groups list', () => {
      expect(findGroupsList().classes()).not.toContain('gl-opacity-5');
    });

    it('shows error message on $emit from item', async () => {
      const errorMessage = 'error message';

      findFirstItem().vm.$emit('error', errorMessage);

      await wrapper.vm.$nextTick();

      expect(findGlAlert().exists()).toBe(true);
      expect(findGlAlert().text()).toContain(errorMessage);
    });

    describe('when searching groups', () => {
      const mockSearchTeam = 'mock search term';

      describe('while groups are loading', () => {
        beforeEach(async () => {
          fetchGroups.mockClear();
          fetchGroups.mockReturnValue(new Promise(() => {}));

          findSearchBox().vm.$emit('input', mockSearchTeam);
          await wrapper.vm.$nextTick();
        });

        it('calls `fetchGroups` with search term', () => {
          expect(fetchGroups).toHaveBeenLastCalledWith(mockGroupsPath, {
            page: 1,
            perPage: DEFAULT_GROUPS_PER_PAGE,
            search: mockSearchTeam,
          });
        });

        it('disables GroupListItems', () => {
          findAllItems().wrappers.forEach((groupListItem) => {
            expect(groupListItem.props('disabled')).toBe(true);
          });
        });

        it('sets opacity of the groups list', () => {
          expect(findGroupsList().classes()).toContain('gl-opacity-5');
        });

        it('sets loading prop of the search box', () => {
          expect(findSearchBox().props('isLoading')).toBe(true);
        });

        it('sets value prop of the search box to the search term', () => {
          expect(findSearchBox().props('value')).toBe(mockSearchTeam);
        });
      });

      describe('when group search finishes loading', () => {
        beforeEach(async () => {
          fetchGroups.mockResolvedValue({ data: [mockGroup1] });
          findSearchBox().vm.$emit('input');

          await waitForPromises();
        });

        it('renders new groups list', () => {
          expect(findAllItems()).toHaveLength(1);
          expect(findFirstItem().props('group')).toBe(mockGroup1);
        });
      });

      it.each`
        userSearchTerm | finalSearchTerm
        ${'gitl'}      | ${'gitl'}
        ${'git'}       | ${'git'}
        ${'gi'}        | ${''}
        ${'g'}         | ${''}
        ${''}          | ${''}
        ${undefined}   | ${undefined}
      `(
        'searches for "$finalSearchTerm" when user enters "$userSearchTerm"',
        async ({ userSearchTerm, finalSearchTerm }) => {
          fetchGroups.mockResolvedValue({
            data: [mockGroup1],
            headers: { 'X-PAGE': 1, 'X-TOTAL': 1 },
          });

          createComponent();
          await waitForPromises();

          const searchBox = findSearchBox();
          searchBox.vm.$emit('input', userSearchTerm);

          expect(fetchGroups).toHaveBeenLastCalledWith(mockGroupsPath, {
            page: 1,
            perPage: DEFAULT_GROUPS_PER_PAGE,
            search: finalSearchTerm,
          });
        },
      );
    });

    describe('when page=2', () => {
      beforeEach(async () => {
        const totalItems = DEFAULT_GROUPS_PER_PAGE + 1;
        const mockGroups = createMockGroups(totalItems);
        fetchGroups.mockResolvedValue({
          headers: { 'X-TOTAL': totalItems, 'X-PAGE': 1 },
          data: mockGroups,
        });
        createComponent();
        await waitForPromises();

        const paginationEl = findPagination();
        paginationEl.vm.$emit('input', 2);
      });

      it('should load results for page 2', () => {
        expect(fetchGroups).toHaveBeenLastCalledWith(mockGroupsPath, {
          page: 2,
          perPage: DEFAULT_GROUPS_PER_PAGE,
          search: '',
        });
      });

      it('resets page to 1 on search `input` event', () => {
        const mockSearchTerm = 'gitlab';
        const searchBox = findSearchBox();

        searchBox.vm.$emit('input', mockSearchTerm);

        expect(fetchGroups).toHaveBeenLastCalledWith(mockGroupsPath, {
          page: 1,
          perPage: DEFAULT_GROUPS_PER_PAGE,
          search: mockSearchTerm,
        });
      });
    });
  });

  describe('pagination', () => {
    it.each`
      scenario                        | totalItems                     | shouldShowPagination
      ${'renders pagination'}         | ${DEFAULT_GROUPS_PER_PAGE + 1} | ${true}
      ${'does not render pagination'} | ${DEFAULT_GROUPS_PER_PAGE}     | ${false}
      ${'does not render pagination'} | ${2}                           | ${false}
      ${'does not render pagination'} | ${0}                           | ${false}
    `('$scenario with $totalItems groups', async ({ totalItems, shouldShowPagination }) => {
      const mockGroups = createMockGroups(totalItems);
      fetchGroups.mockResolvedValue({
        headers: { 'X-TOTAL': totalItems, 'X-PAGE': 1 },
        data: mockGroups,
      });
      createComponent();
      await waitForPromises();

      const paginationEl = findPagination();

      expect(paginationEl.exists()).toBe(shouldShowPagination);
      if (shouldShowPagination) {
        expect(paginationEl.props('totalItems')).toBe(totalItems);
      }
    });

    describe('when `input` event triggered', () => {
      beforeEach(async () => {
        const MOCK_TOTAL_ITEMS = DEFAULT_GROUPS_PER_PAGE + 1;
        fetchGroups.mockResolvedValue({
          headers: { 'X-TOTAL': MOCK_TOTAL_ITEMS, 'X-PAGE': 1 },
          data: createMockGroups(MOCK_TOTAL_ITEMS),
        });

        createComponent();
        await waitForPromises();
      });

      it('executes `fetchGroups` with correct arguments', () => {
        const paginationEl = findPagination();
        paginationEl.vm.$emit('input', 2);

        expect(fetchGroups).toHaveBeenLastCalledWith(mockGroupsPath, {
          page: 2,
          perPage: DEFAULT_GROUPS_PER_PAGE,
          search: '',
        });
      });
    });
  });
});
