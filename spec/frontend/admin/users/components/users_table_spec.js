import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import AdminUsersTable from '~/admin/users/components/users_table.vue';
import AdminUserAvatar from '~/admin/users/components/user_avatar.vue';
import { users, paths } from '../mock_data';

describe('AdminUsersTable component', () => {
  let wrapper;

  const getCellByLabel = (trIdx, label) => {
    return wrapper
      .find(GlTable)
      .find('tbody')
      .findAll('tr')
      .at(trIdx)
      .find(`[data-label="${label}"][role="cell"]`);
  };

  const initComponent = (props = {}) => {
    wrapper = mount(AdminUsersTable, {
      propsData: {
        users,
        paths,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when there are users', () => {
    const user = users[0];

    beforeEach(() => {
      initComponent();
    });

    it.each`
      key                 | label
      ${'name'}           | ${'Name'}
      ${'projectsCount'}  | ${'Projects'}
      ${'createdAt'}      | ${'Created on'}
      ${'lastActivityOn'} | ${'Last activity'}
    `('renders users.$key in column $label', ({ key, label }) => {
      expect(getCellByLabel(0, label).text()).toContain(`${user[key]}`);
    });

    it('renders an AdminUserAvatar component', () => {
      expect(getCellByLabel(0, 'Name').find(AdminUserAvatar).exists()).toBe(true);
    });
  });

  describe('when users is an empty array', () => {
    beforeEach(() => {
      initComponent({ users: [] });
    });

    it('renders a "No users found" message', () => {
      expect(wrapper.text()).toContain('No users found');
    });
  });
});
