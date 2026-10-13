import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserListsTable from '~/user_lists/components/user_lists_table.vue';
import { userList } from 'jest/feature_flags/mock_data';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

describe('User Lists Table', () => {
  let wrapper;
  let userLists;

  const findName = () => wrapper.findByTestId('ffUserListName');
  const findIds = () => wrapper.findByTestId('ffUserListIds');
  const findTimestamp = () => wrapper.findByTestId('ffUserListTimestamp');
  const findTimeAgo = () => wrapper.findComponent(TimeAgo);
  const findAllUserLists = () => wrapper.findAllByTestId('ffUserList');
  const findEditButton = () => wrapper.findByTestId('edit-user-list');
  const findDeleteButton = () => wrapper.findByTestId('delete-user-list');
  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    userLists = new Array(5).fill(userList).map((x, i) => ({ ...x, id: i }));
    wrapper = mountExtended(UserListsTable, {
      propsData: { userLists },
    });
  });

  it("displays a user list's details", () => {
    expect(findName().text()).toBe(userList.name);
    expect(findIds().text()).toBe(userList.user_xids.replace(/,/g, ', '));
    expect(findTimestamp().text()).toContain('created');
  });

  it('passes the created timestamp to TimeAgo', () => {
    expect(findTimeAgo().props('time')).toBe(userList.created_at);
  });

  it('renders a row per user list', () => {
    expect(findAllUserLists()).toHaveLength(5);
    expect(wrapper.findAllByTestId('ffUserListName')).toHaveLength(5);
    expect(wrapper.findAllByTestId('ffUserListIds')).toHaveLength(5);
    expect(wrapper.findAllByTestId('ffUserListTimestamp')).toHaveLength(5);
  });

  describe('edit button', () => {
    it('links to the user list path', () => {
      expect(findEditButton().attributes('href')).toBe(userList.path);
    });
  });

  describe('delete button', () => {
    it('shows the delete confirmation for the list', async () => {
      findDeleteButton().trigger('click');

      await nextTick();
      expect(findModal().text()).toContain(`Delete ${userList.name}?`);
      expect(findModal().text()).toContain(`User list ${userList.name} will be removed.`);
    });
  });

  describe('confirmation modal', () => {
    beforeEach(async () => {
      findDeleteButton().trigger('click');

      await nextTick();
    });

    it('emits delete on confirmation', async () => {
      findModal().vm.$emit('primary');

      await nextTick();
      expect(wrapper.emitted('delete')).toEqual([[userLists[0]]]);
    });

    it('does not emit delete when dismissed', async () => {
      findModal().vm.$emit('canceled');

      await nextTick();
      expect(wrapper.emitted('delete')).toBeUndefined();
    });
  });
});
