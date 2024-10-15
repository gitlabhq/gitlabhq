import { GlTable, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CreatedAt from '~/members/components/table/created_at.vue';
import ExpirationDatepicker from '~/members/components/table/expiration_datepicker.vue';
import MemberActions from '~/members/components/table/member_actions.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import MemberSource from '~/members/components/table/member_source.vue';
import MemberActivity from '~/members/components/table/member_activity.vue';
import MembersTable from '~/members/components/table/members_table.vue';
import MembersPagination from '~/members/components/table/members_pagination.vue';
import MaxRole from '~/members/components/table/max_role.vue';
import RoleDetailsDrawer from '~/members/components/table/drawer/role_details_drawer.vue';
import {
  MEMBERS_TAB_TYPES,
  MEMBER_STATE_CREATED,
  MEMBER_STATE_AWAITING,
  MEMBER_STATE_ACTIVE,
  USER_STATE_BLOCKED,
  BADGE_LABELS_AWAITING_SIGNUP,
  BADGE_LABELS_PENDING,
  TAB_QUERY_PARAM_VALUES,
} from '~/members/constants';
import {
  member as memberMock,
  directMember,
  updateableMember,
  invite,
  accessRequest,
  privateGroup,
  pagination,
} from '../../mock_data';

Vue.use(Vuex);

describe('MembersTable', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.user]: {
          namespaced: true,
          state: {
            members: [],
            memberPath: 'user/path/:id',
            tableFields: [],
            tableAttrs: {
              tr: { 'data-testid': 'member-row' },
            },
            pagination,
            ...state,
          },
        },
      },
    });
  };

  const createComponent = (state, { showRoleDetailsInDrawer = true } = {}) => {
    wrapper = mountExtended(MembersTable, {
      propsData: {
        tabQueryParamValue: TAB_QUERY_PARAM_VALUES.invite,
      },
      store: createStore(state),
      provide: {
        sourceId: 1,
        currentUserId: 1,
        canManageMembers: true,
        namespace: MEMBERS_TAB_TYPES.user,
        namespaceReachedLimit: false,
        namespaceUserLimit: 1,
        glFeatures: { showRoleDetailsInDrawer },
      },
      stubs: {
        RemoveGroupLinkModal: true,
        RemoveMemberModal: true,
        MemberActions: true,
        MaxRole: true,
        RoleDetailsDrawer: true,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findRoleDetailsDrawer = () => wrapper.findComponent(RoleDetailsDrawer);
  const findRoleButton = () => wrapper.findComponent(GlButton);
  const findTableCellByMemberId = (tableCellLabel, memberId) =>
    wrapper
      .findByTestId(`members-table-row-${memberId}`)
      .find(`[data-label="${tableCellLabel}"][role="cell"]`);

  describe('fields', () => {
    const memberCanUpdate = {
      ...directMember,
      canUpdate: true,
    };

    describe.each`
      field           | label           | member             | expectedComponent
      ${'account'}    | ${'Account'}    | ${memberMock}      | ${MemberAvatar}
      ${'source'}     | ${'Source'}     | ${memberMock}      | ${MemberSource}
      ${'invited'}    | ${'Invited'}    | ${invite}          | ${CreatedAt}
      ${'requested'}  | ${'Requested'}  | ${accessRequest}   | ${CreatedAt}
      ${'maxRole'}    | ${'Role'}       | ${memberCanUpdate} | ${MaxRole}
      ${'expiration'} | ${'Expiration'} | ${memberMock}      | ${ExpirationDatepicker}
      ${'activity'}   | ${'Activity'}   | ${memberMock}      | ${MemberActivity}
    `('$label field', ({ field, label, member, expectedComponent }) => {
      beforeEach(() => {
        createComponent(
          { members: [member], tableFields: [field] },
          { showRoleDetailsInDrawer: false },
        );
      });

      it('shows the table header', () => {
        expect(wrapper.findByText(label, { selector: 'th span' }).exists()).toBe(true);
      });

      it('shows the expected component', () => {
        expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
      });
    });

    describe('Role column', () => {
      const createMaxRoleComponent = (member = memberMock) => {
        createComponent({ members: [member], tableFields: ['maxRole'] });
      };

      it('shows the role button', () => {
        createMaxRoleComponent();

        expect(findRoleButton().text()).toBe('Owner');
      });
    });

    describe('Invited column', () => {
      describe.each`
        state                    | userState             | expectedBadgeLabel
        ${MEMBER_STATE_CREATED}  | ${null}               | ${BADGE_LABELS_AWAITING_SIGNUP}
        ${MEMBER_STATE_CREATED}  | ${USER_STATE_BLOCKED} | ${BADGE_LABELS_PENDING}
        ${MEMBER_STATE_AWAITING} | ${''}                 | ${BADGE_LABELS_AWAITING_SIGNUP}
        ${MEMBER_STATE_AWAITING} | ${USER_STATE_BLOCKED} | ${BADGE_LABELS_PENDING}
        ${MEMBER_STATE_AWAITING} | ${'something_else'}   | ${BADGE_LABELS_PENDING}
        ${MEMBER_STATE_ACTIVE}   | ${null}               | ${''}
        ${MEMBER_STATE_ACTIVE}   | ${'something_else'}   | ${''}
      `('Invited Badge', ({ state, userState, expectedBadgeLabel }) => {
        it(`${
          expectedBadgeLabel ? 'shows' : 'hides'
        } invited badge if user status: '${userState}' and member state: '${state}'`, () => {
          createComponent({
            members: [
              {
                ...invite,
                state,
                invite: {
                  ...invite.invite,
                  userState,
                },
              },
            ],
            tableFields: ['invited'],
          });

          const invitedTab = wrapper.findByTestId('invited-badge');

          if (expectedBadgeLabel) {
            expect(invitedTab.text()).toBe(expectedBadgeLabel);
          } else {
            expect(invitedTab.exists()).toBe(false);
          }
        });
      });
    });

    describe('"Actions" field', () => {
      it('renders "Actions" field for screen readers', () => {
        createComponent({ members: [memberCanUpdate], tableFields: ['actions'] });

        const actionField = wrapper.findByTestId('col-actions');

        expect(actionField.exists()).toBe(true);
        expect(actionField.classes('gl-sr-only')).toBe(true);
        expect(
          wrapper.find(`[data-label="Actions"][role="cell"]`).findComponent(MemberActions).exists(),
        ).toBe(true);
      });

      describe('when user is not logged in', () => {
        it('does not render the "Actions" field', () => {
          createComponent({ tableFields: ['actions'] }, { currentUserId: null });

          expect(wrapper.findByTestId('col-actions').exists()).toBe(false);
        });
      });

      const memberCanRemove = {
        ...directMember,
        canRemove: true,
      };

      const memberCanRemoveBlockedLastOwner = {
        ...directMember,
        canRemove: false,
        isLastOwner: true,
      };

      const memberNoPermissions = {
        ...memberMock,
        id: 2,
      };

      describe.each`
        permission                       | members
        ${'canUpdate'}                   | ${[memberNoPermissions, memberCanUpdate]}
        ${'canRemove'}                   | ${[memberNoPermissions, memberCanRemove]}
        ${'canRemoveBlockedByLastOwner'} | ${[memberNoPermissions, memberCanRemoveBlockedLastOwner]}
        ${'canResend'}                   | ${[memberNoPermissions, invite]}
      `('when one of the members has $permission permissions', ({ members }) => {
        it('renders the "Actions" field', () => {
          createComponent({ members, tableFields: ['actions'] });

          expect(wrapper.findByTestId('col-actions').exists()).toBe(true);

          expect(findTableCellByMemberId('Actions', members[0].id).classes()).toStrictEqual([
            'col-actions',
            '!gl-hidden',
            'lg:!gl-table-cell',
            '!gl-align-middle',
          ]);
          expect(findTableCellByMemberId('Actions', members[1].id).classes()).toStrictEqual([
            'col-actions',
            '!gl-align-middle',
          ]);
        });
      });

      describe.each`
        permission                       | members
        ${'canUpdate'}                   | ${[memberMock]}
        ${'canRemove'}                   | ${[memberMock]}
        ${'canRemoveBlockedByLastOwner'} | ${[memberMock]}
        ${'canResend'}                   | ${[{ ...invite, invite: { ...invite.invite, canResend: false } }]}
      `('when none of the members have $permission permissions', ({ members }) => {
        it('does not render the "Actions" field', () => {
          createComponent({ members, tableFields: ['actions'] });

          expect(wrapper.findByTestId('col-actions').exists()).toBe(false);
        });
      });
    });

    describe('Source field', () => {
      beforeEach(() => {
        createComponent({
          members: [privateGroup],
          tableFields: ['source'],
        });
      });

      it('passes correct props to `MemberSource` component', () => {
        expect(wrapper.findComponent(MemberSource).props()).toMatchObject({
          member: privateGroup,
        });
      });
    });
  });

  describe('when `members` is an empty array', () => {
    it('displays a "No results found" message', () => {
      createComponent();

      expect(wrapper.findComponent(EmptyResult).exists()).toBe(true);
    });
  });

  describe('role details drawer', () => {
    it('creates role details drawer with no member selected', () => {
      createComponent();

      expect(findRoleDetailsDrawer().props('member')).toBe(null);
    });

    it('does not show drawer if showRoleDetailsInDrawer feature flag is off', () => {
      createComponent(null, { showRoleDetailsInDrawer: false });

      expect(findRoleDetailsDrawer().exists()).toBe(false);
    });

    describe('with member selected', () => {
      beforeEach(() => {
        createComponent({ members: [updateableMember], tableFields: ['maxRole'] });
        return findRoleButton().trigger('click');
      });

      it('passes member to drawer', () => {
        expect(findRoleDetailsDrawer().props('member')).toEqual(updateableMember);
      });

      it('clears member when drawer is closed', async () => {
        findRoleDetailsDrawer().vm.$emit('close');
        await nextTick();

        expect(findRoleDetailsDrawer().props('member')).toBe(null);
      });

      it.each([true, false])(
        'enables/disables role button when drawer busy state is %s',
        async (busy) => {
          findRoleDetailsDrawer().vm.$emit('busy', busy);
          await nextTick();

          expect(findRoleButton().props('disabled')).toBe(busy);
        },
      );
    });
  });

  describe('QA testid', () => {
    const createMaxRoleComponent = (member = memberMock) => {
      createComponent({ members: [member], tableFields: ['maxRole'] });
    };

    it('adds testid to table row', () => {
      createMaxRoleComponent();

      expect(findTable().find('tbody tr').attributes('data-testid')).toContain('members-table-row');
    });
  });

  it('renders `members-pagination` component with correct props', () => {
    createComponent();
    const membersPagination = wrapper.findComponent(MembersPagination);

    expect(membersPagination.props()).toMatchObject({
      pagination,
      tabQueryParamValue: TAB_QUERY_PARAM_VALUES.invite,
    });
  });
});
