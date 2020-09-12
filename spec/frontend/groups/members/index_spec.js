import { createWrapper } from '@vue/test-utils';
import initGroupMembersApp from '~/groups/members';
import GroupMembersApp from '~/groups/members/components/app.vue';
import { membersJsonString, membersParsed } from './mock_data';

describe('initGroupMembersApp', () => {
  let el;
  let wrapper;

  const setup = () => {
    const vm = initGroupMembersApp(el);
    wrapper = createWrapper(vm);
  };

  const getGroupMembersApp = () => wrapper.find(GroupMembersApp);

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-members', membersJsonString);
    el.setAttribute('data-current-user-id', '123');
    el.setAttribute('data-group-id', '234');

    document.body.appendChild(el);
  });

  afterEach(() => {
    document.body.innerHTML = '';
    el = null;

    wrapper.destroy();
    wrapper = null;
  });

  it('parses and passes `currentUserId` prop to `GroupMembersApp`', () => {
    setup();

    expect(getGroupMembersApp().props('currentUserId')).toBe(123);
  });

  it('does not pass `currentUserId` prop if not provided by the data attribute (user is not logged in)', () => {
    el.removeAttribute('data-current-user-id');
    setup();

    expect(getGroupMembersApp().props('currentUserId')).toBeNull();
  });

  it('parses and passes `groupId` prop to `GroupMembersApp`', () => {
    setup();

    expect(getGroupMembersApp().props('groupId')).toBe(234);
  });

  it('parses and passes `members` prop to `GroupMembersApp`', () => {
    setup();

    expect(getGroupMembersApp().props('members')).toEqual(membersParsed);
  });
});
