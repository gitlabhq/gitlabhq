import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import CollapsedAssignee from '~/sidebar/components/assignees/collapsed_assignee.vue';
import CollapsedAssigneeList from '~/sidebar/components/assignees/collapsed_assignee_list.vue';

const DEFAULT_MAX_COUNTER = 99;

describe('CollapsedAssigneeList component', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      users: [],
      issuableType: 'merge_request',
      ...props,
    };

    wrapper = shallowMount(CollapsedAssigneeList, {
      propsData,
    });
  }

  const findNoUsersIcon = () => wrapper.findComponent(GlIcon);
  const findAvatarCounter = () => wrapper.find('.avatar-counter');
  const findAssignees = () => wrapper.findAllComponents(CollapsedAssignee);
  const getTooltipTitle = () => wrapper.attributes('title');

  describe('No assignees/users', () => {
    beforeEach(() => {
      createComponent({
        users: [],
      });
    });

    it('has no users', () => {
      expect(findNoUsersIcon().exists()).toBe(true);
      expect(findNoUsersIcon().props('name')).toBe('user');
    });
  });

  describe('One assignee/user', () => {
    let users;

    beforeEach(() => {
      users = UsersMockHelper.createNumberRandomUsers(1);
    });

    it('should not show no users icon', () => {
      createComponent({ users });

      expect(findNoUsersIcon().exists()).toBe(false);
    });

    it('has correct "cannot merge" tooltip when user cannot merge', () => {
      users[0].can_merge = false;

      createComponent({ users });

      expect(getTooltipTitle()).toContain('cannot merge');
    });

    it('does not have "merge" word in tooltip if user can merge', () => {
      users[0].can_merge = true;

      createComponent({ users });

      expect(getTooltipTitle()).not.toContain('merge');
    });
  });

  describe('More than one assignees/users', () => {
    let users;

    beforeEach(() => {
      users = UsersMockHelper.createNumberRandomUsers(2);

      createComponent({ users });
    });

    it('has multiple-users class', () => {
      expect(wrapper.classes('multiple-users')).toBe(true);
    });

    it('does not display an avatar count', () => {
      expect(findAvatarCounter().exists()).toBe(false);
    });

    it('returns just two collapsed users', () => {
      expect(findAssignees().length).toBe(2);
    });
  });

  describe('More than two assignees/users', () => {
    let users;
    let userNames;

    beforeEach(() => {
      users = UsersMockHelper.createNumberRandomUsers(3);
      userNames = users.map((x) => x.name).join(', ');
    });

    describe('default', () => {
      beforeEach(() => {
        createComponent({ users });
      });

      it('does display an avatar count', () => {
        expect(findAvatarCounter().exists()).toBe(true);
        expect(findAvatarCounter().text()).toEqual('+2');
      });

      it('returns one collapsed users', () => {
        expect(findAssignees().length).toBe(1);
      });
    });

    it('has corrent "no one can merge" tooltip when no one can merge', () => {
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = false;

      createComponent({
        users,
      });

      expect(getTooltipTitle()).toEqual(`${userNames} (no one can merge)`);
    });

    it('has correct "cannot merge" tooltip when one user can merge', () => {
      users[0].can_merge = true;
      users[1].can_merge = false;
      users[2].can_merge = false;

      createComponent({
        users,
      });

      expect(getTooltipTitle()).toEqual(`${userNames} (1/3 can merge)`);
    });

    it('has correct "cannot merge" tooltip when more than one user can merge', () => {
      users[0].can_merge = false;
      users[1].can_merge = true;
      users[2].can_merge = true;

      createComponent({
        users,
      });

      expect(getTooltipTitle()).toEqual(`${userNames} (2/3 can merge)`);
    });

    it('does not have "merge" in tooltip if everyone can merge', () => {
      users[0].can_merge = true;
      users[1].can_merge = true;
      users[2].can_merge = true;

      createComponent({
        users,
      });

      expect(getTooltipTitle()).toEqual(userNames);
    });

    it('displays the correct avatar count', () => {
      users = UsersMockHelper.createNumberRandomUsers(5);

      createComponent({
        users,
      });

      expect(findAvatarCounter().text()).toEqual(`+${users.length - 1}`);
    });

    it('displays the correct avatar count via a computed property if more than default max counter', () => {
      users = UsersMockHelper.createNumberRandomUsers(100);

      createComponent({
        users,
      });

      expect(findAvatarCounter().text()).toEqual(`${DEFAULT_MAX_COUNTER}+`);
    });
  });

  const [busyUser] = UsersMockHelper.createNumberRandomUsers(1);
  const [canMergeUser] = UsersMockHelper.createNumberRandomUsers(1);
  busyUser.availability = 'busy';
  canMergeUser.can_merge = true;

  describe.each`
    users                       | busy | canMerge | expected
    ${[busyUser, canMergeUser]} | ${1} | ${1}     | ${`${busyUser.name} (Busy), ${canMergeUser.name} (1/2 can merge)`}
    ${[busyUser]}               | ${1} | ${0}     | ${`${busyUser.name} (Busy) (cannot merge)`}
    ${[canMergeUser]}           | ${0} | ${1}     | ${`${canMergeUser.name}`}
    ${[]}                       | ${0} | ${0}     | ${'Assignees'}
  `(
    'with $users.length users, $busy is busy and $canMerge that can merge',
    ({ users, expected }) => {
      it('generates the tooltip text', () => {
        createComponent({ users });

        expect(getTooltipTitle()).toEqual(expected);
      });
    },
  );
});
