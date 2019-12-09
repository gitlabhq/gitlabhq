import { shallowMount } from '@vue/test-utils';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import CollapsedAssigneeList from '~/sidebar/components/assignees/collapsed_assignee_list.vue';
import CollapsedAssignee from '~/sidebar/components/assignees/collapsed_assignee.vue';

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
      attachToDocument: true,
      propsData,
      sync: false,
    });
  }

  const findNoUsersIcon = () => wrapper.find('i[aria-label=None]');
  const findAvatarCounter = () => wrapper.find('.avatar-counter');
  const findAssignees = () => wrapper.findAll(CollapsedAssignee);
  const getTooltipTitle = () => wrapper.attributes('data-original-title');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('No assignees/users', () => {
    beforeEach(() => {
      createComponent({
        users: [],
      });
    });

    it('has no users', () => {
      expect(findNoUsersIcon().exists()).toBe(true);
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
      userNames = users.map(x => x.name).join(', ');
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
});
