import { GlAlert, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { fetchGroups } from '~/jira_connect/api';
import GroupsList from '~/jira_connect/components/groups_list.vue';
import GroupsListItem from '~/jira_connect/components/groups_list_item.vue';
import { mockGroup1, mockGroup2 } from '../mock_data';

jest.mock('~/jira_connect/api', () => {
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
          expect(fetchGroups).toHaveBeenCalledWith(mockGroupsPath, {
            page: 1,
            perPage: 10,
            search: mockSearchTeam,
          });
        });

        it('disables GroupListItems', async () => {
          findAllItems().wrappers.forEach((groupListItem) => {
            expect(groupListItem.props('disabled')).toBe(true);
          });
        });

        it('sets opacity of the groups list', () => {
          expect(findGroupsList().classes()).toContain('gl-opacity-5');
        });

        it('sets loading prop of ths search box', () => {
          expect(findSearchBox().props('isLoading')).toBe(true);
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
    });
  });
});
