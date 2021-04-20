import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import AdminUserActions from '~/admin/users/components/user_actions.vue';
import AdminUserAvatar from '~/admin/users/components/user_avatar.vue';
import AdminUsersTable from '~/admin/users/components/users_table.vue';
import AdminUserDate from '~/vue_shared/components/user_date.vue';

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

    it('renders the projects count', () => {
      expect(getCellByLabel(0, 'Projects').text()).toContain(`${user.projectsCount}`);
    });

    it('renders the user actions', () => {
      expect(wrapper.find(AdminUserActions).exists()).toBe(true);
    });

    it.each`
      component          | label
      ${AdminUserAvatar} | ${'Name'}
      ${AdminUserDate}   | ${'Created on'}
      ${AdminUserDate}   | ${'Last activity'}
    `('renders the component for column $label', ({ component, label }) => {
      expect(getCellByLabel(0, label).find(component).exists()).toBe(true);
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
