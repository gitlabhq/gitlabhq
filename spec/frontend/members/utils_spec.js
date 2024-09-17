import setWindowLocation from 'helpers/set_window_location_helper';
import {
  DEFAULT_SORT,
  MEMBERS_TAB_TYPES,
  I18N_USER_YOU,
  I18N_USER_BLOCKED,
  I18N_USER_BOT,
  I188N_USER_2FA,
} from '~/members/constants';
import {
  generateBadges,
  isGroup,
  isCurrentUser,
  canRemove,
  canRemoveBlockedByLastOwner,
  canResend,
  canUpdate,
  canDisableTwoFactor,
  canOverride,
  parseSortParam,
  buildSortHref,
  parseDataAttributes,
  groupLinkRequestFormatter,
  roleDropdownItems,
  initialSelectedRole,
  handleMemberRoleUpdate,
} from '~/members/utils';
import showGlobalToast from '~/vue_shared/plugins/global_toast';
import { BASE_ROLES } from '~/access_level/constants';
import {
  member as memberMock,
  directMember,
  inheritedMember,
  member2faEnabled,
  group,
  invite,
  members,
  pagination,
  dataAttribute,
} from './mock_data';

jest.mock('~/vue_shared/plugins/global_toast');

const IS_CURRENT_USER_ID = 123;
const IS_NOT_CURRENT_USER_ID = 124;
const URL_HOST = 'https://localhost/';

describe('Members Utils', () => {
  describe('generateBadges', () => {
    it('has correct properties for each badge', () => {
      const badges = generateBadges({
        member: memberMock,
        isCurrentUser: true,
        canManageMembers: true,
      });

      badges.forEach((badge) => {
        expect(badge).toEqual(
          expect.objectContaining({
            show: expect.any(Boolean),
            text: expect.any(String),
            variant: expect.stringMatching(/muted|neutral|info|success|danger|warning/),
          }),
        );
      });
    });

    it.each`
      member                                                            | expected
      ${memberMock}                                                     | ${{ show: true, text: I18N_USER_YOU, variant: 'success' }}
      ${{ ...memberMock, user: { ...memberMock.user, blocked: true } }} | ${{ show: true, text: I18N_USER_BLOCKED, variant: 'danger' }}
      ${{ ...memberMock, user: { ...memberMock.user, isBot: true } }}   | ${{ show: true, text: I18N_USER_BOT, variant: 'muted' }}
      ${member2faEnabled}                                               | ${{ show: true, text: I188N_USER_2FA, variant: 'info' }}
    `('returns expected output for "$expected.text" badge', ({ member, expected }) => {
      expect(
        generateBadges({ member, isCurrentUser: true, canManageMembers: true }),
      ).toContainEqual(expect.objectContaining(expected));
    });

    describe('when `canManageMembers` argument is `false`', () => {
      describe.each`
        description                  | memberIsCurrentUser | expectedBadgeToBeShown
        ${'is not the current user'} | ${false}            | ${false}
        ${'is the current user'}     | ${true}             | ${true}
      `('when member is $description', ({ memberIsCurrentUser, expectedBadgeToBeShown }) => {
        it(`sets 'show' to '${expectedBadgeToBeShown}' for 2FA badge`, () => {
          const badges = generateBadges({
            member: member2faEnabled,
            isCurrentUser: memberIsCurrentUser,
            canManageMembers: false,
          });

          expect(badges.find((badge) => badge.text === '2FA').show).toBe(expectedBadgeToBeShown);
        });
      });
    });
  });

  describe('isGroup', () => {
    it.each`
      member        | expected
      ${group}      | ${true}
      ${memberMock} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(isGroup(member)).toBe(expected);
    });
  });

  describe('isCurrentUser', () => {
    it.each`
      currentUserId             | expected
      ${IS_CURRENT_USER_ID}     | ${true}
      ${IS_NOT_CURRENT_USER_ID} | ${false}
    `('returns $expected', ({ currentUserId, expected }) => {
      expect(isCurrentUser(memberMock, currentUserId)).toBe(expected);
    });
  });

  describe('canRemove', () => {
    it.each`
      member                                     | expected
      ${{ ...directMember, canRemove: true }}    | ${true}
      ${{ ...inheritedMember, canRemove: true }} | ${false}
      ${{ ...memberMock, canRemove: false }}     | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(canRemove(member)).toBe(expected);
    });
  });

  describe('canRemoveBlockedByLastOwner', () => {
    it.each`
      member                                        | canManageMembers | expected
      ${{ ...directMember, isLastOwner: true }}     | ${true}          | ${true}
      ${{ ...inheritedMember, isLastOwner: false }} | ${true}          | ${false}
      ${{ ...directMember, isLastOwner: true }}     | ${false}         | ${false}
    `('returns $expected', ({ member, canManageMembers, expected }) => {
      expect(canRemoveBlockedByLastOwner(member, canManageMembers)).toBe(expected);
    });
  });

  describe('canResend', () => {
    it.each`
      member                                                           | expected
      ${invite}                                                        | ${true}
      ${{ ...invite, invite: { ...invite.invite, canResend: false } }} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(canResend(member)).toBe(expected);
    });
  });

  describe('canUpdate', () => {
    it.each`
      member                                     | currentUserId             | expected
      ${{ ...directMember, canUpdate: true }}    | ${IS_NOT_CURRENT_USER_ID} | ${true}
      ${{ ...directMember, canUpdate: true }}    | ${IS_CURRENT_USER_ID}     | ${false}
      ${{ ...inheritedMember, canUpdate: true }} | ${IS_CURRENT_USER_ID}     | ${false}
      ${{ ...directMember, canUpdate: false }}   | ${IS_NOT_CURRENT_USER_ID} | ${false}
    `('returns $expected', ({ member, currentUserId, expected }) => {
      expect(canUpdate(member, currentUserId)).toBe(expected);
    });
  });

  describe('canDisableTwoFactor', () => {
    it.each`
      member                                           | expected
      ${{ ...memberMock, canDisableTwoFactor: true }}  | ${false}
      ${{ ...memberMock, canDisableTwoFactor: false }} | ${false}
    `(
      'returns $expected for members whose two factor authentication can be disabled',
      ({ member, expected }) => {
        expect(canDisableTwoFactor(member)).toBe(expected);
      },
    );
  });

  describe('canOverride', () => {
    it('returns `false`', () => {
      expect(canOverride(memberMock)).toBe(false);
    });
  });

  describe('parseSortParam', () => {
    beforeEach(() => {
      setWindowLocation(URL_HOST);
    });

    describe('when `sort` param is not present', () => {
      it('returns default sort options', () => {
        expect(parseSortParam(['account'])).toEqual(DEFAULT_SORT);
      });
    });

    describe('when field passed in `sortableFields` argument does not have `sort` key defined', () => {
      it('returns default sort options', () => {
        setWindowLocation('?sort=source_asc');

        expect(parseSortParam(['source'])).toEqual(DEFAULT_SORT);
      });
    });

    describe.each`
      sortParam              | expected
      ${'name_asc'}          | ${{ sortByKey: 'account', sortDesc: false }}
      ${'name_desc'}         | ${{ sortByKey: 'account', sortDesc: true }}
      ${'last_joined'}       | ${{ sortByKey: 'granted', sortDesc: false }}
      ${'oldest_joined'}     | ${{ sortByKey: 'granted', sortDesc: true }}
      ${'access_level_asc'}  | ${{ sortByKey: 'maxRole', sortDesc: false }}
      ${'access_level_desc'} | ${{ sortByKey: 'maxRole', sortDesc: true }}
      ${'recent_sign_in'}    | ${{ sortByKey: 'lastSignIn', sortDesc: false }}
      ${'oldest_sign_in'}    | ${{ sortByKey: 'lastSignIn', sortDesc: true }}
    `('when `sort` query string param is `$sortParam`', ({ sortParam, expected }) => {
      it(`returns ${JSON.stringify(expected)}`, () => {
        setWindowLocation(`?sort=${sortParam}`);

        expect(parseSortParam(['account', 'granted', 'expires', 'maxRole', 'lastSignIn'])).toEqual(
          expected,
        );
      });
    });
  });

  describe('buildSortHref', () => {
    beforeEach(() => {
      setWindowLocation(URL_HOST);
    });

    describe('when field passed in `sortBy` argument does not have `sort` key defined', () => {
      it('returns an empty string', () => {
        expect(
          buildSortHref({
            sortBy: 'source',
            sortDesc: false,
            filteredSearchBarTokens: [],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe('');
      });
    });

    describe('when there are no filter params set', () => {
      it('sets `sort` param', () => {
        expect(
          buildSortHref({
            sortBy: 'account',
            sortDesc: false,
            filteredSearchBarTokens: [],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe(`${URL_HOST}?sort=name_asc`);
      });
    });

    describe('when filter params are set', () => {
      it('merges the `sort` param with the filter params', () => {
        setWindowLocation('?two_factor=enabled&with_inherited_permissions=exclude');

        expect(
          buildSortHref({
            sortBy: 'account',
            sortDesc: false,
            filteredSearchBarTokens: ['two_factor', 'with_inherited_permissions'],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe(`${URL_HOST}?two_factor=enabled&with_inherited_permissions=exclude&sort=name_asc`);
      });
    });

    describe('when search param is set', () => {
      it('merges the `sort` param with the search param', () => {
        setWindowLocation('?search=foobar');

        expect(
          buildSortHref({
            sortBy: 'account',
            sortDesc: false,
            filteredSearchBarTokens: ['two_factor', 'with_inherited_permissions'],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe(`${URL_HOST}?search=foobar&sort=name_asc`);
      });
    });
  });

  describe('parseDataAttributes', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
      el.dataset.membersData = dataAttribute;
    });

    afterEach(() => {
      el = null;
    });

    it('correctly parses the data attribute', () => {
      expect(parseDataAttributes(el)).toMatchObject({
        [MEMBERS_TAB_TYPES.user]: {
          members,
          pagination,
          memberPath: '/groups/foo-bar/-/group_members/:id',
        },
        sourceId: 234,
        canManageMembers: true,
      });
    });
  });

  describe('groupLinkRequestFormatter', () => {
    it('returns expected format', () => {
      expect(
        groupLinkRequestFormatter({
          accessLevel: 50,
          expires_at: '2020-10-16',
        }),
      ).toEqual({
        group_link: { group_access: 50, expires_at: '2020-10-16', member_role_id: null },
      });

      expect(
        groupLinkRequestFormatter({
          accessLevel: 50,
          expires_at: '2020-10-16',
          memberRoleId: 80,
        }),
      ).toEqual({
        group_link: { group_access: 50, expires_at: '2020-10-16', member_role_id: 80 },
      });
    });
  });

  describe('roleDropdownItems', () => {
    it('returns properly flatten and formatted dropdowns', () => {
      const roles = roleDropdownItems(members[0]);

      expect(roles).toEqual({ flatten: BASE_ROLES, formatted: BASE_ROLES });
    });
  });

  describe('initialSelectedRole', () => {
    it('find and return correct value', () => {
      const role = { accessLevel: 10, memberRoleId: null, text: 'Guest', value: 'role-static-0' };
      const initialRole = initialSelectedRole([role], { accessLevel: { integerValue: 10 } });

      expect(initialRole).toBe(role);
    });
  });

  describe('handleMemberRoleUpdate', () => {
    const update = {
      currentRole: 'guest',
      requestedRole: 'dev',
      response: { data: {} },
    };

    it('shows a toast', () => {
      handleMemberRoleUpdate(update);
      expect(showGlobalToast).toHaveBeenCalledWith('Role updated successfully.');
    });

    it('returns requested role', () => {
      const role = handleMemberRoleUpdate(update);
      expect(role).toBe(update.requestedRole);
    });
  });
});
