import { createWrapper } from '@vue/test-utils';
import { initAdminUsersApp } from '~/admin/users';
import AdminUsersApp from '~/admin/users/components/app.vue';
import { users, paths } from './mock_data';

describe('initAdminUsersApp', () => {
  let wrapper;
  let el;

  const findApp = () => wrapper.find(AdminUsersApp);

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-users', JSON.stringify(users));
    el.setAttribute('data-paths', JSON.stringify(paths));

    document.body.appendChild(el);

    wrapper = createWrapper(initAdminUsersApp(el));
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    el.remove();
    el = null;
  });

  it('parses and passes props', () => {
    expect(findApp().props()).toMatchObject({
      users,
      paths,
    });
  });
});
