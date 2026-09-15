import MockAdapter from 'axios-mock-adapter';
import {
  memberName,
  groupErrorsByMessage,
  searchUsers,
  triggerExternalAlert,
  baseBindingAttributes,
} from '~/invite_members/utils/member_utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/lib/utils/url_utility');

describe('Member Name', () => {
  it.each([
    [{ username: '_username_', name: '_name_' }, '_username_'],
    [{ username: '_username_' }, '_username_'],
    [{ name: '_name_' }, '_name_'],
    [{}, undefined],
  ])(`returns name from supplied member token: %j`, (member, result) => {
    expect(memberName(member)).toBe(result);
  });
});

describe('groupErrorsByMessage', () => {
  const toDisplayName = (member) => `@${member}`;

  it('returns one entry per distinct message, in first-appearance order', () => {
    expect(groupErrorsByMessage({ alice: 'error one', bob: 'error two' }, toDisplayName)).toEqual([
      { id: 'alice', displayedMemberNames: '@alice', message: 'error one' },
      { id: 'bob', displayedMemberNames: '@bob', message: 'error two' },
    ]);
  });

  it('groups members that share a message into one entry', () => {
    expect(
      groupErrorsByMessage(
        { alice: 'shared error', bob: 'other error', carol: 'shared error', dan: 'shared error' },
        toDisplayName,
      ),
    ).toEqual([
      {
        id: 'alice,carol,dan',
        displayedMemberNames: '@alice, @carol, and @dan',
        message: 'shared error',
      },
      { id: 'bob', displayedMemberNames: '@bob', message: 'other error' },
    ]);
  });

  it('joins two members with "and"', () => {
    expect(groupErrorsByMessage({ alice: 'error', bob: 'error' }, toDisplayName)).toEqual([
      { id: 'alice,bob', displayedMemberNames: '@alice and @bob', message: 'error' },
    ]);
  });

  it('omits members the resolver cannot name', () => {
    expect(groupErrorsByMessage({ alice: 'error', bob: 'error' }, () => undefined)).toEqual([
      { id: 'alice,bob', displayedMemberNames: '', message: 'error' },
    ]);
  });

  it('returns an empty list for no errors', () => {
    expect(groupErrorsByMessage({}, toDisplayName)).toEqual([]);
  });
});

describe('searchUsers', () => {
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  it('should call axios.get with correct URL and params', async () => {
    const url = 'https://example.com/gitlab/groups/mygroup/-/group_members/invite_search.json';
    const search = 'my user';
    mockAxios.onGet().replyOnce(HTTP_STATUS_OK);

    await searchUsers(url, search);
    expect(mockAxios.history.get[0]).toEqual(
      expect.objectContaining({ url, params: { search, per_page: 20 } }),
    );
  });
});

describe('Trigger External Alert', () => {
  it('returns false', () => {
    expect(triggerExternalAlert()).toBe(false);
  });
});

describe('baseBindingAttributes', () => {
  it('returns empty object', () => {
    expect(baseBindingAttributes()).toEqual({});
  });
});
