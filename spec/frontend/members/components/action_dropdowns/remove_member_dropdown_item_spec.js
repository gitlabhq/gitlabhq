import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { modalData } from 'jest/members/mock_data';
import RemoveMemberDropdownItem from '~/members/components/action_dropdowns/remove_member_dropdown_item.vue';
import { MEMBER_TYPES } from '~/members/constants';

Vue.use(Vuex);

describe('RemoveMemberDropdownItem', () => {
  let wrapper;
  const text = 'dummy';

  const actions = {
    showRemoveMemberModal: jest.fn(),
  };

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            memberPath: '/groups/foo-bar/-/group_members/:id',
            ...state,
          },
          actions,
        },
      },
    });
  };

  const createComponent = (propsData = {}, state) => {
    wrapper = shallowMount(RemoveMemberDropdownItem, {
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      propsData: {
        memberId: 1,
        memberType: 'GroupMember',
        modalMessage: 'Are you sure you want to remove John Smith?',
        isAccessRequest: true,
        isInvite: true,
        userDeletionObstacles: { name: 'user', obstacles: [] },
        ...propsData,
      },
      slots: {
        default: text,
      },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a slot with red text', () => {
    expect(findDropdownItem().html()).toContain(`<span class="gl-text-red-500">${text}</span>`);
  });

  it('calls Vuex action to show `remove member` modal when clicked', () => {
    findDropdownItem().vm.$emit('click');

    expect(actions.showRemoveMemberModal).toHaveBeenCalledWith(expect.any(Object), modalData);
  });
});
