import MockAdapter from 'axios-mock-adapter';
import { memberName, searchUsers, triggerExternalAlert } from '~/invite_members/utils/member_utils';
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
