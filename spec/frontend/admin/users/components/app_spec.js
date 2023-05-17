import { shallowMount } from '@vue/test-utils';

import AdminUsersApp from '~/admin/users/components/app.vue';
import AdminUsersTable from '~/admin/users/components/users_table.vue';
import { users, paths } from '../mock_data';

describe('AdminUsersApp component', () => {
  let wrapper;

  const initComponent = (props = {}) => {
    wrapper = shallowMount(AdminUsersApp, {
      propsData: {
        users,
        paths,
        ...props,
      },
    });
  };

  describe('when initialized', () => {
    beforeEach(() => {
      initComponent();
    });

    it('renders the admin users table with props', () => {
      expect(wrapper.findComponent(AdminUsersTable).props()).toEqual({
        users,
        paths,
      });
    });
  });
});
