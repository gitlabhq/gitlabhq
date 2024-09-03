import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import * as timeago from 'timeago.js';
import { nextTick } from 'vue';
import { timeagoLanguageCode } from '~/lib/utils/datetime/timeago_utility';
import UserListsTable from '~/user_lists/components/user_lists_table.vue';
import { userList } from 'jest/feature_flags/mock_data';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';

jest.mock('timeago.js', () => ({
  format: jest.fn().mockReturnValue('2 weeks ago'),
  register: jest.fn(),
}));

describe('User Lists Table', () => {
  let wrapper;
  let userLists;

  beforeEach(() => {
    userLists = new Array(5).fill(userList).map((x, i) => ({ ...x, id: i }));
    wrapper = mount(UserListsTable, {
      propsData: { userLists },
    });
  });

  it('should display the details of a user list', () => {
    expect(wrapper.find('[data-testid="ffUserListName"]').text()).toBe(userList.name);
    expect(wrapper.find('[data-testid="ffUserListIds"]').text()).toBe(
      userList.user_xids.replace(/,/g, ', '),
    );
    expect(wrapper.find('[data-testid="ffUserListTimestamp"]').text()).toBe('created 2 weeks ago');
    expect(timeago.format).toHaveBeenCalledWith(newDate(userList.created_at), timeagoLanguageCode);
  });

  it('should set the title for a tooltip on the created stamp', () => {
    expect(wrapper.find('[data-testid="ffUserListTimestamp"]').attributes('title')).toBe(
      localeDateFormat.asDateTimeFull.format(userList.created_at),
    );
  });

  it('should display a user list entry per user list', () => {
    const lists = wrapper.findAll('[data-testid="ffUserList"]');
    expect(lists).toHaveLength(5);
    lists.wrappers.forEach((list) => {
      expect(list.find('[data-testid="ffUserListName"]').exists()).toBe(true);
      expect(list.find('[data-testid="ffUserListIds"]').exists()).toBe(true);
      expect(list.find('[data-testid="ffUserListTimestamp"]').exists()).toBe(true);
    });
  });

  describe('edit button', () => {
    it('should link to the path for the user list', () => {
      expect(wrapper.find('[data-testid="edit-user-list"]').attributes('href')).toBe(userList.path);
    });
  });

  describe('delete button', () => {
    it('should display the confirmation modal', async () => {
      const modal = wrapper.findComponent(GlModal);

      wrapper.find('[data-testid="delete-user-list"]').trigger('click');

      await nextTick();
      expect(modal.text()).toContain(`Delete ${userList.name}?`);
      expect(modal.text()).toContain(`User list ${userList.name} will be removed.`);
    });
  });

  describe('confirmation modal', () => {
    let modal;

    beforeEach(async () => {
      modal = wrapper.findComponent(GlModal);

      wrapper.find('button').trigger('click');

      await nextTick();
    });

    it('should emit delete with list on confirmation', async () => {
      modal.find('[data-testid="modal-confirm"]').trigger('click');

      await nextTick();
      expect(wrapper.emitted('delete')).toEqual([[userLists[0]]]);
    });

    it('should not emit delete with list when not confirmed', async () => {
      modal.find('button').trigger('click');

      await nextTick();
      expect(wrapper.emitted('delete')).toBeUndefined();
    });
  });
});
