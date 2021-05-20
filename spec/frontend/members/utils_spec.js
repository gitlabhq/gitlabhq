import { DEFAULT_SORT, MEMBER_TYPES } from '~/members/constants';
import {
  generateBadges,
  isGroup,
  isDirectMember,
  isCurrentUser,
  canRemove,
  canResend,
  canUpdate,
  canOverride,
  parseSortParam,
  buildSortHref,
  parseDataAttributes,
  groupLinkRequestFormatter,
} from '~/members/utils';
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
      ${memberMock}                                                     | ${{ show: true, text: "It's you", variant: 'success' }}
      ${{ ...memberMock, user: { ...memberMock.user, blocked: true } }} | ${{ show: true, text: 'Blocked', variant: 'danger' }}
      ${member2faEnabled}                                               | ${{ show: true, text: '2FA', variant: 'info' }}
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
    test.each`
      member        | expected
      ${group}      | ${true}
      ${memberMock} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(isGroup(member)).toBe(expected);
    });
  });

  describe('isDirectMember', () => {
    test.each`
      member             | expected
      ${directMember}    | ${true}
      ${inheritedMember} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(isDirectMember(member)).toBe(expected);
    });
  });

  describe('isCurrentUser', () => {
    test.each`
      currentUserId             | expected
      ${IS_CURRENT_USER_ID}     | ${true}
      ${IS_NOT_CURRENT_USER_ID} | ${false}
    `('returns $expected', ({ currentUserId, expected }) => {
      expect(isCurrentUser(memberMock, currentUserId)).toBe(expected);
    });
  });

  describe('canRemove', () => {
    test.each`
      member                                     | expected
      ${{ ...directMember, canRemove: true }}    | ${true}
      ${{ ...inheritedMember, canRemove: true }} | ${false}
      ${{ ...memberMock, canRemove: false }}     | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(canRemove(member)).toBe(expected);
    });
  });

  describe('canResend', () => {
    test.each`
      member                                                           | expected
      ${invite}                                                        | ${true}
      ${{ ...invite, invite: { ...invite.invite, canResend: false } }} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(canResend(member)).toBe(expected);
    });
  });

  describe('canUpdate', () => {
    test.each`
      member                                     | currentUserId             | expected
      ${{ ...directMember, canUpdate: true }}    | ${IS_NOT_CURRENT_USER_ID} | ${true}
      ${{ ...directMember, canUpdate: true }}    | ${IS_CURRENT_USER_ID}     | ${false}
      ${{ ...inheritedMember, canUpdate: true }} | ${IS_CURRENT_USER_ID}     | ${false}
      ${{ ...directMember, canUpdate: false }}   | ${IS_NOT_CURRENT_USER_ID} | ${false}
    `('returns $expected', ({ member, currentUserId, expected }) => {
      expect(canUpdate(member, currentUserId)).toBe(expected);
    });
  });

  describe('canOverride', () => {
    it('returns `false`', () => {
      expect(canOverride(memberMock)).toBe(false);
    });
  });

  describe('parseSortParam', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(URL_HOST);
    });

    describe('when `sort` param is not present', () => {
      it('returns default sort options', () => {
        window.location.search = '';

        expect(parseSortParam(['account'])).toEqual(DEFAULT_SORT);
      });
    });

    describe('when field passed in `sortableFields` argument does not have `sort` key defined', () => {
      it('returns default sort options', () => {
        window.location.search = '?sort=source_asc';

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
      it(`returns ${JSON.stringify(expected)}`, async () => {
        window.location.search = `?sort=${sortParam}`;

        expect(parseSortParam(['account', 'granted', 'expires', 'maxRole', 'lastSignIn'])).toEqual(
          expected,
        );
      });
    });
  });

  describe('buildSortHref', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(URL_HOST);
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
        window.location.search = '?two_factor=enabled&with_inherited_permissions=exclude';

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
        window.location.search = '?search=foobar';

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
      el.setAttribute('data-members-data', dataAttribute);
    });

    afterEach(() => {
      el = null;
    });

    it('correctly parses the data attribute', () => {
      expect(parseDataAttributes(el)).toMatchObject({
        [MEMBER_TYPES.user]: {
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
      ).toEqual({ group_link: { group_access: 50, expires_at: '2020-10-16' } });
    });
  });
});
