import { createWrapper } from '@vue/test-utils';
import MembersTabs from '~/members/components/members_tabs.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { initMembersApp } from '~/members/index';
import { members, pagination, dataAttribute } from './mock_data';

describe('initMembersApp', () => {
  let el;
  let vm;
  let wrapper;

  const setup = () => {
    vm = initMembersApp(el, {
      [MEMBER_TYPES.user]: {
        tableFields: ['account'],
        tableAttrs: { table: { 'data-qa-selector': 'members_list' } },
        tableSortableFields: ['account'],
        requestFormatter: () => ({}),
        filteredSearchBar: { show: false },
      },
    });
    wrapper = createWrapper(vm);
  };

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-members-data', dataAttribute);

    window.gon = { current_user_id: 123 };
  });

  afterEach(() => {
    el = null;

    wrapper.destroy();
    wrapper = null;
  });

  it('renders `MembersTabs`', () => {
    setup();

    expect(wrapper.find(MembersTabs).exists()).toBe(true);
  });

  it('parses and sets `members` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].members).toEqual(members);
  });

  it('parses and sets `pagination` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].pagination).toEqual(pagination);
  });

  it('sets `tableFields` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].tableFields).toEqual(['account']);
  });

  it('sets `tableAttrs` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].tableAttrs).toEqual({
      table: { 'data-qa-selector': 'members_list' },
    });
  });

  it('sets `tableSortableFields` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].tableSortableFields).toEqual(['account']);
  });

  it('sets `requestFormatter` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].requestFormatter()).toEqual({});
  });

  it('sets `filteredSearchBar` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].filteredSearchBar).toEqual({ show: false });
  });

  it('sets `memberPath` in Vuex store', () => {
    setup();

    expect(vm.$store.state[MEMBER_TYPES.user].memberPath).toBe(
      '/groups/foo-bar/-/group_members/:id',
    );
  });
});
