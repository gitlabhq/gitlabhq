import { createWrapper } from '@vue/test-utils';
import { initAdminUsersApp, initAdminUserActions } from '~/admin/users';
import AdminUsersApp from '~/admin/users/components/app.vue';
import UserActions from '~/admin/users/components/user_actions.vue';
import { users, user, paths } from './mock_data';

describe('initAdminUsersApp', () => {
  let wrapper;
  let el;

  const findApp = () => wrapper.find(AdminUsersApp);

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-users', JSON.stringify(users));
    el.setAttribute('data-paths', JSON.stringify(paths));

    wrapper = createWrapper(initAdminUsersApp(el));
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    el = null;
  });

  it('parses and passes props', () => {
    expect(findApp().props()).toMatchObject({
      users,
      paths,
    });
  });
});

describe('initAdminUserActions', () => {
  let wrapper;
  let el;

  const findUserActions = () => wrapper.find(UserActions);

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-user', JSON.stringify(user));
    el.setAttribute('data-paths', JSON.stringify(paths));

    wrapper = createWrapper(initAdminUserActions(el));
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    el = null;
  });

  it('parses and passes props', () => {
    expect(findUserActions().props()).toMatchObject({
      user,
      paths,
    });
  });
});
