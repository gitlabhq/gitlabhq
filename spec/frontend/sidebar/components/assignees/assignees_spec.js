import { GlAvatar, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import Assignee from '~/sidebar/components/assignees/assignees.vue';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';
import CollapsedAssigneeList from '~/sidebar/components/assignees/collapsed_assignee_list.vue';
import UsersMock from '../../mock_data';

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
    });
  };

  const findAllAvatarLinks = () => wrapper.findAllComponents(AssigneeAvatarLink);
  const findComponentTextNoUsers = () => wrapper.find('[data-testid="no-value"]');
  const findCollapsedChildren = () => wrapper.findAll('.sidebar-collapsed-icon > *');

  describe('No assignees/users', () => {
    it('displays no assignee icon when collapsed', () => {
      createWrapper();
      const collapsedChildren = findCollapsedChildren();
      const userIcon = collapsedChildren.at(0).findComponent(GlIcon);

      expect(collapsedChildren.length).toBe(1);
      expect(collapsedChildren.at(0).attributes('aria-label')).toBe('None');
      expect(userIcon.exists()).toBe(true);
      expect(userIcon.props('name')).toBe('user');
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

    it('emits the assign-self event when "assign yourself" is clicked', async () => {
      createWrapper({
        ...getDefaultProps(),
        editable: true,
      });

      await wrapper.find('[data-testid="assign-yourself"]').trigger('click');

      expect(wrapper.emitted('assign-self')).toHaveLength(1);
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
      expect(assignee.findComponent(GlAvatar).props('src')).toBe(UsersMock.user.avatar);
      expect(assignee.findComponent(GlAvatar).props('alt')).toBe(`${UsersMock.user.name}'s avatar`);

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

      expect(first.findComponent(GlAvatar).props('src')).toBe(users[0].avatar_url);
      expect(first.findComponent(GlAvatar).props('alt')).toBe(`${users[0].name}'s avatar`);

      expect(trimText(first.find('.author').text())).toBe(users[0].name);

      const second = collapsedChildren.at(1);

      expect(second.findComponent(GlAvatar).props('src')).toBe(users[1].avatar_url);
      expect(second.findComponent(GlAvatar).props('alt')).toBe(`${users[1].name}'s avatar`);

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

      expect(first.findComponent(GlAvatar).props('src')).toBe(users[0].avatar_url);
      expect(first.findComponent(GlAvatar).props('alt')).toBe(`${users[0].name}'s avatar`);

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

      expect(findAllAvatarLinks()).toHaveLength(users.length);
      expect(wrapper.find('[data-testid="user-list-more"]').exists()).toBe(false);
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

      expect(wrapper.findComponent(CollapsedAssigneeList).props('users')[0]).toEqual(
        expect.objectContaining({
          can_merge: true,
        }),
      );
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

      const userItems = findAllAvatarLinks();

      expect(userItems).toHaveLength(3);
      expect(userItems.at(0).attributes()).toMatchObject({
        'data-user-id': `${users[2].id}`,
        'data-username': users[2].username,
      });
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
