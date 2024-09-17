import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MembersTableCell from '~/members/components/table/members_table_cell.vue';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import { canRemoveBlockedByLastOwner } from '~/members/utils';
import {
  member as memberMock,
  directMember,
  inheritedMember,
  group,
  invite,
  accessRequest,
} from '../../mock_data';

jest.mock('~/members/utils', () => ({
  ...jest.requireActual('~/members/utils'),
  canRemoveBlockedByLastOwner: jest.fn().mockImplementation(() => true),
}));

describe('MembersTableCell', () => {
  const WrappedComponent = {
    props: {
      memberType: {
        type: String,
        required: true,
      },
      isCurrentUser: {
        type: Boolean,
        required: true,
      },
      permissions: {
        type: Object,
        required: true,
      },
    },
    render(createElement) {
      return createElement('div', this.memberType);
    },
  };

  Vue.use(Vuex);
  Vue.component('WrappedComponent', WrappedComponent);

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state,
    });
  };

  let wrapper;

  const createComponent = (propsData, state) => {
    wrapper = mount(MembersTableCell, {
      propsData,
      store: createStore(state),
      provide: {
        sourceId: 1,
        currentUserId: 1,
        canManageMembers: true,
      },
      scopedSlots: {
        default: `
          <wrapped-component
            :member-type="props.memberType"
            :is-current-user="props.isCurrentUser"
            :permissions="props.permissions"
          />
        `,
      },
    });
  };

  const findWrappedComponent = () => wrapper.findComponent(WrappedComponent);

  const memberCurrentUser = {
    ...memberMock,
    user: {
      ...memberMock.user,
      id: 1,
    },
  };

  const createComponentWithDirectMember = (member = {}) => {
    createComponent({
      member: { ...directMember, ...member },
    });
  };
  const createComponentWithInheritedMember = (member = {}) => {
    createComponent({
      member: { ...inheritedMember, ...member },
    });
  };

  it.each`
    member           | expectedMemberType
    ${memberMock}    | ${MEMBERS_TAB_TYPES.user}
    ${group}         | ${MEMBERS_TAB_TYPES.group}
    ${invite}        | ${MEMBERS_TAB_TYPES.invite}
    ${accessRequest} | ${MEMBERS_TAB_TYPES.accessRequest}
  `(
    'sets scoped slot prop `memberType` to $expectedMemberType',
    ({ member, expectedMemberType }) => {
      createComponent({ member });

      expect(findWrappedComponent().props('memberType')).toBe(expectedMemberType);
    },
  );

  describe('isCurrentUser', () => {
    it('returns `true` when `member.user` has the same ID as `currentUserId`', () => {
      createComponent({
        member: memberCurrentUser,
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

  describe('permissions', () => {
    describe('canRemove', () => {
      describe('for a direct member', () => {
        it('returns `true` when `canRemove` is `true`', () => {
          createComponentWithDirectMember({
            canRemove: true,
          });

          expect(findWrappedComponent().props('permissions').canRemove).toBe(true);
        });

        it('returns `false` when `canRemove` is `false`', () => {
          createComponentWithDirectMember({
            canRemove: false,
          });

          expect(findWrappedComponent().props('permissions').canRemove).toBe(false);
        });
      });

      describe('for an inherited member', () => {
        it('returns `false`', () => {
          createComponentWithInheritedMember();

          expect(findWrappedComponent().props('permissions').canRemove).toBe(false);
        });
      });
    });

    describe('canRemoveBlockedByLastOwner', () => {
      it('calls util and returns value', () => {
        createComponentWithDirectMember();

        expect(canRemoveBlockedByLastOwner).toHaveBeenCalledWith(directMember, true);
        expect(findWrappedComponent().props('permissions').canRemoveBlockedByLastOwner).toBe(true);
      });
    });

    describe('canResend', () => {
      describe('when member type is `invite`', () => {
        it('returns `true` when `canResend` is `true`', () => {
          createComponent({
            member: invite,
          });

          expect(findWrappedComponent().props('permissions').canResend).toBe(true);
        });

        it('returns `false` when `canResend` is `false`', () => {
          createComponent({
            member: {
              ...invite,
              invite: {
                ...invite,
                canResend: false,
              },
            },
          });

          expect(findWrappedComponent().props('permissions').canResend).toBe(false);
        });
      });

      describe('when member type is not `invite`', () => {
        it('returns `false`', () => {
          createComponent({ member: memberMock });

          expect(findWrappedComponent().props('permissions').canResend).toBe(false);
        });
      });
    });

    describe('canUpdate', () => {
      describe('for a direct member', () => {
        it('returns `true` when `canUpdate` is `true`', () => {
          createComponentWithDirectMember({
            canUpdate: true,
          });

          expect(findWrappedComponent().props('permissions').canUpdate).toBe(true);
        });

        it('returns `false` when `canUpdate` is `false`', () => {
          createComponentWithDirectMember({
            canUpdate: false,
          });

          expect(findWrappedComponent().props('permissions').canUpdate).toBe(false);
        });

        it('returns `false` for current user', () => {
          createComponentWithDirectMember(memberCurrentUser);

          expect(findWrappedComponent().props('permissions').canUpdate).toBe(false);
        });
      });

      describe('for an inherited member', () => {
        it('returns `false`', () => {
          createComponentWithInheritedMember();

          expect(findWrappedComponent().props('permissions').canUpdate).toBe(false);
        });
      });
    });
  });
});
