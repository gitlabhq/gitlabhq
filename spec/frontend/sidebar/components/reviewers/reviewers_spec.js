import { GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import { TEST_HOST } from 'helpers/test_constants';
import Reviewer from '~/sidebar/components/reviewers/reviewers.vue';

const usersMock = (id = 1) => ({
  id,
  name: 'Root',
  state: 'active',
  username: 'root',
  webUrl: `${TEST_HOST}/root`,
  avatarUrl: `${TEST_HOST}/avatar/root.png`,
  mergeRequestInteraction: {
    canMerge: true,
    canUpdate: true,
    reviewed: true,
    approved: false,
  },
});

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

  describe('No reviewers/users', () => {
    it('displays no reviewer icon when collapsed', () => {
      createWrapper();
      const collapsedChildren = findCollapsedChildren();
      const userIcon = collapsedChildren.at(0).findComponent(GlIcon);

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
        users: [usersMock()],
      });

      const collapsedChildren = findCollapsedChildren();
      const reviewer = collapsedChildren.at(0);

      expect(collapsedChildren.length).toBe(1);
      expect(reviewer.find('.avatar').attributes('src')).toContain('avatar/root.png');
      expect(reviewer.find('.avatar').attributes('alt')).toBe(`Root's avatar`);

      expect(trimText(reviewer.find('.author').text())).toBe('Root');
    });
  });

  describe('Two or more reviewers/users', () => {
    it('displays two reviewer icons when collapsed', () => {
      const users = [usersMock(), usersMock(2)];
      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedChildren = findCollapsedChildren();

      expect(collapsedChildren.length).toBe(2);

      const first = collapsedChildren.at(0);

      expect(first.find('.avatar').attributes('src')).toBe(users[0].avatarUrl);
      expect(first.find('.avatar').attributes('alt')).toBe(`${users[0].name}'s avatar`);

      expect(trimText(first.find('.author').text())).toBe(users[0].name);

      const second = collapsedChildren.at(1);

      expect(second.find('.avatar').attributes('src')).toBe(users[1].avatarUrl);
      expect(second.find('.avatar').attributes('alt')).toBe(`${users[1].name}'s avatar`);

      expect(trimText(second.find('.author').text())).toBe(users[1].name);
    });

    it('displays one reviewer icon and counter when collapsed', () => {
      const users = [usersMock(), usersMock(2), usersMock(3)];
      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedChildren = findCollapsedChildren();

      expect(collapsedChildren.length).toBe(2);

      const first = collapsedChildren.at(0);

      expect(first.find('.avatar').attributes('src')).toBe(users[0].avatarUrl);
      expect(first.find('.avatar').attributes('alt')).toBe(`${users[0].name}'s avatar`);

      expect(trimText(first.find('.author').text())).toBe(users[0].name);

      const second = collapsedChildren.at(1);

      expect(trimText(second.find('.avatar-counter').text())).toBe('+2');
    });

    it('Shows two reviewers', () => {
      const users = [usersMock(), usersMock(2)];
      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.findAll('[data-testid="reviewer"]').length).toBe(users.length);
    });

    it('shows sorted reviewer where "can merge" users are sorted first', () => {
      const users = [usersMock(), usersMock(2), usersMock(3)];
      users[0].mergeRequestInteraction.canMerge = false;
      users[1].mergeRequestInteraction.canMerge = false;
      users[2].mergeRequestInteraction.canMerge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.vm.sortedReviewers[0].mergeRequestInteraction.canMerge).toBe(true);
    });

    it('passes the sorted reviewers to the uncollapsed-reviewer-list', () => {
      const users = [usersMock(), usersMock(2), usersMock(3)];
      users[0].mergeRequestInteraction.canMerge = false;
      users[1].mergeRequestInteraction.canMerge = false;
      users[2].mergeRequestInteraction.canMerge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const userItems = wrapper.findAll('[data-testid="reviewer"]');

      expect(userItems.length).toBe(3);
    });

    it('passes the sorted reviewers to the collapsed-reviewer-list', () => {
      const users = [usersMock(), usersMock(2), usersMock(3)];
      users[0].mergeRequestInteraction.canMerge = false;
      users[1].mergeRequestInteraction.canMerge = false;
      users[2].mergeRequestInteraction.canMerge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const collapsedButton = wrapper.find('.sidebar-collapsed-user button');

      expect(trimText(collapsedButton.text())).toBe(users[2].name);
    });
  });
});
