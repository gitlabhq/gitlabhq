import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
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
describe('GroupsList', () => {
  let wrapper;

  const mockEmptyResponse = { data: [] };

  const createComponent = (options = {}) => {
    wrapper = shallowMount(GroupsList, {
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findAllItems = () => wrapper.findAll(GroupsListItem);
  const findFirstItem = () => findAllItems().at(0);
  const findSecondItem = () => findAllItems().at(1);

  describe('isLoading is true', () => {
    it('renders loading icon', async () => {
      fetchGroups.mockResolvedValue(mockEmptyResponse);
      createComponent();

      wrapper.setData({ isLoading: true });
      await wrapper.vm.$nextTick();

      expect(findGlLoadingIcon().exists()).toBe(true);
    });
  });

  describe('no groups returned', () => {
    it('renders empty state', async () => {
      fetchGroups.mockResolvedValue(mockEmptyResponse);
      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toContain('No available namespaces');
    });
  });

  describe('with groups returned', () => {
    it('renders groups list', async () => {
      fetchGroups.mockResolvedValue({ data: [mockGroup1, mockGroup2] });
      createComponent();

      await waitForPromises();

      expect(findAllItems().length).toBe(2);
      expect(findFirstItem().props('group')).toBe(mockGroup1);
      expect(findSecondItem().props('group')).toBe(mockGroup2);
    });
  });
});
