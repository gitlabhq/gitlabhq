import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { MEMBER_TYPES } from '~/vue_shared/components/members/constants';
import { member as memberMock, group, invite, accessRequest } from '../mock_data';
import MembersTableCell from '~/vue_shared/components/members/table/members_table_cell.vue';

describe('MemberList', () => {
  const WrappedComponent = {
    props: {
      memberType: {
        type: String,
        required: true,
      },
      isDirectMember: {
        type: Boolean,
        required: true,
      },
      isCurrentUser: {
        type: Boolean,
        required: true,
      },
    },
    render(createElement) {
      return createElement('div', this.memberType);
    },
  };

  const localVue = createLocalVue();
  localVue.use(Vuex);
  localVue.component('wrapped-component', WrappedComponent);

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state: {
        sourceId: 1,
        currentUserId: 1,
        ...state,
      },
    });
  };

  let wrapper;

  const createComponent = (propsData, state = {}) => {
    wrapper = mount(MembersTableCell, {
      localVue,
      propsData,
      store: createStore(state),
      scopedSlots: {
        default: `
          <wrapped-component
            :member-type="props.memberType"
            :is-direct-member="props.isDirectMember"
            :is-current-user="props.isCurrentUser"
          />
        `,
      },
    });
  };

  const findWrappedComponent = () => wrapper.find(WrappedComponent);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  test.each`
    member           | expectedMemberType
    ${memberMock}    | ${MEMBER_TYPES.user}
    ${group}         | ${MEMBER_TYPES.group}
    ${invite}        | ${MEMBER_TYPES.invite}
    ${accessRequest} | ${MEMBER_TYPES.accessRequest}
  `(
    'sets scoped slot prop `memberType` to $expectedMemberType',
    ({ member, expectedMemberType }) => {
      createComponent({ member });

      expect(findWrappedComponent().props('memberType')).toBe(expectedMemberType);
    },
  );

  describe('isDirectMember', () => {
    it('returns `true` when member source has same ID as `sourceId`', () => {
      createComponent({
        member: {
          ...memberMock,
          source: {
            ...memberMock.source,
            id: 1,
          },
        },
      });

      expect(findWrappedComponent().props('isDirectMember')).toBe(true);
    });

    it('returns `false` when member is inherited', () => {
      createComponent({
        member: memberMock,
      });

      expect(findWrappedComponent().props('isDirectMember')).toBe(false);
    });
  });

  describe('isCurrentUser', () => {
    it('returns `true` when `member.user` has the same ID as `currentUserId`', () => {
      createComponent({
        member: {
          ...memberMock,
          user: {
            ...memberMock.user,
            id: 1,
          },
        },
      });

      expect(findWrappedComponent().props('isCurrentUser')).toBe(true);
    });

    it('returns `false` when `member.user` does not have the same ID as `currentUserId`', () => {
      createComponent({
        member: memberMock,
      });

      expect(findWrappedComponent().props('isCurrentUser')).toBe(false);
    });
  });
});
