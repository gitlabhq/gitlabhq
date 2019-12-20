import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import Assignee from '~/sidebar/components/assignees/assignees.vue';
import UsersMock from './mock_data';
import UsersMockHelper from '../helpers/user_mock_data_helper';

describe('Assignee component', () => {
  const getDefaultProps = () => ({
    rootPath: 'http://localhost:3000',
    users: [],
    editable: false,
  });
  let wrapper;

  const createWrapper = (propsData = getDefaultProps()) => {
    wrapper = mount(Assignee, {
      propsData,
      sync: false,
      attachToDocument: true,
    });
  };

  const findComponentTextNoUsers = () => wrapper.find('.assign-yourself');
  const findCollapsedChildren = () => wrapper.findAll('.sidebar-collapsed-icon > *');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('No assignees/users', () => {
    it('displays no assignee icon when collapsed', () => {
      createWrapper();
      const collapsedChildren = findCollapsedChildren();

      expect(collapsedChildren.length).toBe(1);
      expect(collapsedChildren.at(0).attributes('aria-label')).toBe('None');
      expect(collapsedChildren.at(0).classes()).toContain('fa', 'fa-user');
    });

    it('displays only "None" when no users are assigned and the issue is read-only', () => {
      createWrapper();
      const componentTextNoUsers = trimText(findComponentTextNoUsers().text());

      expect(componentTextNoUsers).toBe('None');
      expect(componentTextNoUsers).not.toContain('assign yourself');
    });

    it('displays only "None" when no users are assigned and the issue can be edited', () => {
      createWrapper({
        ...getDefaultProps(),
        editable: true,
      });
      const componentTextNoUsers = trimText(findComponentTextNoUsers().text());

      expect(componentTextNoUsers).toContain('None');
      expect(componentTextNoUsers).toContain('assign yourself');
    });

    it('emits the assign-self event when "assign yourself" is clicked', () => {
      createWrapper({
        ...getDefaultProps(),
        editable: true,
      });

      jest.spyOn(wrapper.vm, '$emit');
      wrapper.find('.assign-yourself .btn-link').trigger('click');

      expect(wrapper.emitted('assign-self')).toBeTruthy();
    });
  });

  describe('One assignee/user', () => {
    it('displays one assignee icon when collapsed', () => {
      createWrapper({
        ...getDefaultProps(),
        users: [UsersMock.user],
      });

      const collapsedChildren = findCollapsedChildren();
      const assignee = collapsedChildren.at(0);

      expect(collapsedChildren.length).toBe(1);
      expect(assignee.find('.avatar').attributes('src')).toBe(UsersMock.user.avatar);
      expect(assignee.find('.avatar').attributes('alt')).toBe(`${UsersMock.user.name}'s avatar`);

      expect(trimText(assignee.find('.author').text())).toBe(UsersMock.user.name);
    });
  });

  describe('Two or more assignees/users', () => {
    it('displays two assignee icons when collapsed', () => {
      const users = UsersMockHelper.createNumberRandomUsers(2);
      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedChildren = findCollapsedChildren();

      expect(collapsedChildren.length).toBe(2);

      const first = collapsedChildren.at(0);

      expect(first.find('.avatar').attributes('src')).toBe(users[0].avatar);
      expect(first.find('.avatar').attributes('alt')).toBe(`${users[0].name}'s avatar`);

      expect(trimText(first.find('.author').text())).toBe(users[0].name);

      const second = collapsedChildren.at(1);

      expect(second.find('.avatar').attributes('src')).toBe(users[1].avatar);
      expect(second.find('.avatar').attributes('alt')).toBe(`${users[1].name}'s avatar`);

      expect(trimText(second.find('.author').text())).toBe(users[1].name);
    });

    it('displays one assignee icon and counter when collapsed', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedChildren = findCollapsedChildren();

      expect(collapsedChildren.length).toBe(2);

      const first = collapsedChildren.at(0);

      expect(first.find('.avatar').attributes('src')).toBe(users[0].avatar);
      expect(first.find('.avatar').attributes('alt')).toBe(`${users[0].name}'s avatar`);

      expect(trimText(first.find('.author').text())).toBe(users[0].name);

      const second = collapsedChildren.at(1);

      expect(trimText(second.find('.avatar-counter').text())).toBe('+2');
    });

    it('Shows two assignees', () => {
      const users = UsersMockHelper.createNumberRandomUsers(2);
      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.findAll('.user-item').length).toBe(users.length);
      expect(wrapper.find('.user-list-more').exists()).toBe(false);
    });

    it('shows sorted assignee where "can merge" users are sorted first', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.vm.sortedAssigness[0].can_merge).toBe(true);
    });

    it('passes the sorted assignees to the uncollapsed-assignee-list', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const userItems = wrapper.findAll('.user-list .user-item a');

      expect(userItems.length).toBe(3);
      expect(userItems.at(0).attributes('title')).toBe(users[2].name);
    });

    it('passes the sorted assignees to the collapsed-assignee-list', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedButton = wrapper.find('.sidebar-collapsed-user button');

      expect(trimText(collapsedButton.text())).toBe(users[2].name);
    });
  });
});
