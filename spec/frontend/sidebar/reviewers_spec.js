import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import { GlIcon } from '@gitlab/ui';
import Reviewer from '~/sidebar/components/reviewers/reviewers.vue';
import UsersMock from './mock_data';
import UsersMockHelper from '../helpers/user_mock_data_helper';

describe('Reviewer component', () => {
  const getDefaultProps = () => ({
    rootPath: 'http://localhost:3000',
    users: [],
    editable: false,
  });
  let wrapper;

  const createWrapper = (propsData = getDefaultProps()) => {
    wrapper = mount(Reviewer, {
      propsData,
    });
  };

  const findCollapsedChildren = () => wrapper.findAll('.sidebar-collapsed-icon > *');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('No reviewers/users', () => {
    it('displays no reviewer icon when collapsed', () => {
      createWrapper();
      const collapsedChildren = findCollapsedChildren();
      const userIcon = collapsedChildren.at(0).find(GlIcon);

      expect(collapsedChildren.length).toBe(1);
      expect(collapsedChildren.at(0).attributes('aria-label')).toBe('None');
      expect(userIcon.exists()).toBe(true);
      expect(userIcon.props('name')).toBe('user');
    });
  });

  describe('One reviewer/user', () => {
    it('displays one reviewer icon when collapsed', () => {
      createWrapper({
        ...getDefaultProps(),
        users: [UsersMock.user],
      });

      const collapsedChildren = findCollapsedChildren();
      const reviewer = collapsedChildren.at(0);

      expect(collapsedChildren.length).toBe(1);
      expect(reviewer.find('.avatar').attributes('src')).toBe(UsersMock.user.avatar);
      expect(reviewer.find('.avatar').attributes('alt')).toBe(`${UsersMock.user.name}'s avatar`);

      expect(trimText(reviewer.find('.author').text())).toBe(UsersMock.user.name);
    });
  });

  describe('Two or more reviewers/users', () => {
    it('displays two reviewer icons when collapsed', () => {
      const users = UsersMockHelper.createNumberRandomUsers(2);
      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedChildren = findCollapsedChildren();

      expect(collapsedChildren.length).toBe(2);

      const first = collapsedChildren.at(0);

      expect(first.find('.avatar').attributes('src')).toBe(users[0].avatar_url);
      expect(first.find('.avatar').attributes('alt')).toBe(`${users[0].name}'s avatar`);

      expect(trimText(first.find('.author').text())).toBe(users[0].name);

      const second = collapsedChildren.at(1);

      expect(second.find('.avatar').attributes('src')).toBe(users[1].avatar_url);
      expect(second.find('.avatar').attributes('alt')).toBe(`${users[1].name}'s avatar`);

      expect(trimText(second.find('.author').text())).toBe(users[1].name);
    });

    it('displays one reviewer icon and counter when collapsed', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedChildren = findCollapsedChildren();

      expect(collapsedChildren.length).toBe(2);

      const first = collapsedChildren.at(0);

      expect(first.find('.avatar').attributes('src')).toBe(users[0].avatar_url);
      expect(first.find('.avatar').attributes('alt')).toBe(`${users[0].name}'s avatar`);

      expect(trimText(first.find('.author').text())).toBe(users[0].name);

      const second = collapsedChildren.at(1);

      expect(trimText(second.find('.avatar-counter').text())).toBe('+2');
    });

    it('Shows two reviewers', () => {
      const users = UsersMockHelper.createNumberRandomUsers(2);
      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.findAll('.user-item').length).toBe(users.length);
      expect(wrapper.find('.user-list-more').exists()).toBe(false);
    });

    it('shows sorted reviewer where "can merge" users are sorted first', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.vm.sortedReviewers[0].can_merge).toBe(true);
    });

    it('passes the sorted reviewers to the uncollapsed-reviewer-list', () => {
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

    it('passes the sorted reviewers to the collapsed-reviewer-list', () => {
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
