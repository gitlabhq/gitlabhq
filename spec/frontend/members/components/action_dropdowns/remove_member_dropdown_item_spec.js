import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { modalData } from 'jest/members/mock_data';
import RemoveMemberDropdownItem from '~/members/components/action_dropdowns/remove_member_dropdown_item.vue';
import { MEMBERS_TAB_TYPES, MEMBER_MODEL_TYPE_GROUP_MEMBER } from '~/members/constants';

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
        [MEMBERS_TAB_TYPES.user]: {
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
        namespace: MEMBERS_TAB_TYPES.user,
      },
      propsData: {
        memberId: 1,
        memberModelType: MEMBER_MODEL_TYPE_GROUP_MEMBER,
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

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  it('renders a slot with red text', () => {
    expect(findDropdownItem().html()).toContain(`<span class="gl-text-red-500">${text}</span>`);
  });

  it('calls Vuex action to show `remove member` modal when clicked', () => {
    findDropdownItem().vm.$emit('action');

    expect(actions.showRemoveMemberModal).toHaveBeenCalledWith(expect.any(Object), {
      ...modalData,
      preventRemoval: false,
    });
  });
});
