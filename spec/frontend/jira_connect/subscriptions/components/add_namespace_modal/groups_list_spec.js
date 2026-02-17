import {
  GlAlert,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlPagination,
  GlFormCheckbox,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { fetchGroups } from '~/jira_connect/subscriptions/api';
import GroupsList from '~/jira_connect/subscriptions/components/add_namespace_modal/groups_list.vue';
import GroupsListItem from '~/jira_connect/subscriptions/components/add_namespace_modal/groups_list_item.vue';
import { DEFAULT_GROUPS_PER_PAGE } from '~/jira_connect/subscriptions/constants';
import createStore from '~/jira_connect/subscriptions/store';
import { mockGroup1, mockGroup2 } from '../../mock_data';

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

describe('GroupsList', () => {
  let wrapper;
  let store;

  const mockGroupsPath = '/groups';
  const mockAccessToken = '123';
  const mockUser = {
    name: 'test user',
    is_admin: false,
  };

  const createComponent = ({ initialState } = {}) => {
    store = createStore({
      accessToken: mockAccessToken,
      currentUser: mockUser,
      ...initialState,
    });

    wrapper = extendedWrapper(
      shallowMount(GroupsList, {
        store,
        provide: {
          groupsPath: mockGroupsPath,
        },
      }),
    );
  };

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAllItems = () => wrapper.findAllComponents(GroupsListItem);
  const findFirstItem = () => findAllItems().at(0);
  const findSecondItem = () => findAllItems().at(1);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findGroupsList = () => wrapper.findByTestId('groups-list');
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findTopLevelOnlyCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  describe('when groups are loading', () => {
    it('renders loading icon', async () => {
      fetchGroups.mockReturnValue(new Promise(() => {}));
      createComponent();

      await nextTick();

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
      expect(findGlAlert().text()).toBe('Failed to load groups. Please try again.');
    });
  });

  describe('with no groups returned', () => {
    const mockEmptyResponse = { data: [] };

    it('renders empty state', async () => {
      fetchGroups.mockResolvedValue(mockEmptyResponse);
      createComponent();

      await waitForPromises();

      expect(findGlLoadingIcon().exists()).toBe(false);
      expect(wrapper.text()).toContain('No groups found');
    });
  });

  describe('with groups returned', () => {
    beforeEach(async () => {
      fetchGroups.mockResolvedValue({
        headers: { 'X-PAGE': 1, 'X-TOTAL': 2 },
        data: [mockGroup1, mockGroup2],
      });
      createComponent();

      // wait for the initial loadGroups
      // to finish.
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

      await nextTick();

      expect(findGlAlert().exists()).toBe(true);
      expect(findGlAlert().text()).toContain(errorMessage);
    });

    describe('when searching groups', () => {
      const mockSearchTeam = 'mock search term';

      describe('while groups are loading', () => {
        beforeEach(async () => {
          fetchGroups.mockClear();
          // return a never-ending promise to make test
          // deterministic.
          fetchGroups.mockReturnValue(new Promise(() => {}));

          findSearchBox().vm.$emit('input', mockSearchTeam);
          await nextTick();
        });

        it('calls `fetchGroups` with search term', () => {
          expect(fetchGroups).toHaveBeenLastCalledWith(
            mockGroupsPath,
            {
              minAccessLevel: 40,
              page: 1,
              perPage: DEFAULT_GROUPS_PER_PAGE,
              search: mockSearchTeam,
              top_level_only: false,
            },
            mockAccessToken,
          );
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
          findSearchBox().vm.$emit('input', mockSearchTeam);

          await waitForPromises();
        });

        it('renders new groups list', () => {
          expect(findAllItems()).toHaveLength(1);
          expect(findFirstItem().props('group')).toBe(mockGroup1);
        });
      });

      describe.each`
        previousSearch | newSearch | shouldSearch | expectedSearchValue
        ${''}          | ${'git'}  | ${true}      | ${'git'}
        ${'g'}         | ${'git'}  | ${true}      | ${'git'}
        ${'git'}       | ${'gitl'} | ${true}      | ${'gitl'}
        ${'git'}       | ${'gi'}   | ${true}      | ${''}
        ${'gi'}        | ${'g'}    | ${false}     | ${undefined}
        ${'g'}         | ${''}     | ${false}     | ${undefined}
        ${''}          | ${'g'}    | ${false}     | ${undefined}
      `(
        'when previous search was "$previousSearch" and user enters "$newSearch"',
        ({ previousSearch, newSearch, shouldSearch, expectedSearchValue }) => {
          beforeEach(async () => {
            fetchGroups.mockResolvedValue({
              data: [mockGroup1],
              headers: { 'X-PAGE': 1, 'X-TOTAL': 1 },
            });

            // wait for initial load
            createComponent();
            await waitForPromises();

            // set up the "previous search"
            findSearchBox().vm.$emit('input', previousSearch);
            await waitForPromises();

            fetchGroups.mockClear();
          });

          it(`${shouldSearch ? 'should' : 'should not'} execute fetch new results`, () => {
            // enter the new search
            findSearchBox().vm.$emit('input', newSearch);

            if (shouldSearch) {
              expect(fetchGroups).toHaveBeenCalledWith(
                mockGroupsPath,
                {
                  minAccessLevel: 40,
                  page: 1,
                  perPage: DEFAULT_GROUPS_PER_PAGE,
                  search: expectedSearchValue,
                  top_level_only: false,
                },
                mockAccessToken,
              );
            } else {
              expect(fetchGroups).not.toHaveBeenCalled();
            }
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

        // mock the response from page 2
        fetchGroups.mockResolvedValue({
          headers: { 'X-TOTAL': totalItems, 'X-PAGE': 2 },
          data: mockGroups,
        });
        await paginationEl.vm.$emit('input', 2);
      });

      it('should load results for page 2', () => {
        expect(fetchGroups).toHaveBeenLastCalledWith(
          mockGroupsPath,
          {
            minAccessLevel: 40,
            page: 2,
            perPage: DEFAULT_GROUPS_PER_PAGE,
            search: '',
            top_level_only: false,
          },
          mockAccessToken,
        );
      });

      it.each`
        scenario                    | searchTerm  | expectedPage | expectedSearchTerm
        ${'preserves current page'} | ${'gi'}     | ${2}         | ${''}
        ${'resets page to 1'}       | ${'gitlab'} | ${1}         | ${'gitlab'}
      `(
        '$scenario when search term is $searchTerm',
        ({ searchTerm, expectedPage, expectedSearchTerm }) => {
          const searchBox = findSearchBox();
          searchBox.vm.$emit('input', searchTerm);

          expect(fetchGroups).toHaveBeenLastCalledWith(
            mockGroupsPath,
            {
              minAccessLevel: 40,
              page: expectedPage,
              perPage: DEFAULT_GROUPS_PER_PAGE,
              search: expectedSearchTerm,
              top_level_only: false,
            },
            mockAccessToken,
          );
        },
      );
    });
  });

  describe('when user is admin', () => {
    const mockAdmin = {
      name: 'test admin',
      is_admin: true,
    };

    beforeEach(async () => {
      fetchGroups.mockResolvedValue();
      createComponent({
        initialState: {
          currentUser: mockAdmin,
        },
      });

      await waitForPromises();
    });

    it('calls `fetchGroups` without `min_access_level`', () => {
      expect(fetchGroups).toHaveBeenLastCalledWith(
        mockGroupsPath,
        {
          page: 1,
          perPage: DEFAULT_GROUPS_PER_PAGE,
          search: '',
          top_level_only: false,
        },
        mockAccessToken,
      );
    });
  });
  describe('top-level only checkbox', () => {
    const totalItems = DEFAULT_GROUPS_PER_PAGE + 1;
    const mockGroups = createMockGroups(totalItems);
    beforeEach(() => {
      fetchGroups.mockResolvedValue({
        headers: { 'X-PAGE': 1, 'X-TOTAL': totalItems },
        data: mockGroups,
      });
      createComponent();
    });

    it('renders the checkbox', () => {
      expect(findTopLevelOnlyCheckbox().exists()).toBe(true);
      expect(findTopLevelOnlyCheckbox().text()).toBe('Show only top-level groups');
    });

    it('checkbox is unchecked by default', () => {
      expect(findTopLevelOnlyCheckbox().props('checked')).toBe(false);
    });

    describe('when checkbox is checked', () => {
      beforeEach(() => {
        findTopLevelOnlyCheckbox().vm.$emit('input', true);
        findTopLevelOnlyCheckbox().vm.$emit('change', true);
      });

      it('calls `fetchGroups` with top_level_only parameter', () => {
        expect(fetchGroups).toHaveBeenCalledWith(
          mockGroupsPath,
          {
            minAccessLevel: 40,
            page: 1,
            perPage: DEFAULT_GROUPS_PER_PAGE,
            search: '',
            top_level_only: true,
          },
          mockAccessToken,
        );
      });
    });

    describe('when on page 2 and checkbox is toggled', () => {
      beforeEach(() => {
        findPagination().vm.$emit('input', 2);

        fetchGroups.mockClear();
        fetchGroups.mockResolvedValue({
          headers: { 'X-PAGE': 1, 'X-TOTAL': 1 },
          data: [mockGroup1],
        });

        findTopLevelOnlyCheckbox().vm.$emit('input', true);
        findTopLevelOnlyCheckbox().vm.$emit('change', true);
      });

      it('resets page to 1 when toggled', () => {
        expect(fetchGroups).toHaveBeenCalledWith(
          mockGroupsPath,
          {
            minAccessLevel: 40,
            page: 1,
            perPage: DEFAULT_GROUPS_PER_PAGE,
            search: '',
            top_level_only: true,
          },
          mockAccessToken,
        );
        expect(findPagination().exists()).toBe(false);
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

      it('calls `fetchGroups` with correct arguments', () => {
        const paginationEl = findPagination();
        paginationEl.vm.$emit('input', 2);

        expect(fetchGroups).toHaveBeenLastCalledWith(
          mockGroupsPath,
          {
            minAccessLevel: 40,
            page: 2,
            perPage: DEFAULT_GROUPS_PER_PAGE,
            search: '',
            top_level_only: false,
          },
          mockAccessToken,
        );
      });
    });
  });
});
