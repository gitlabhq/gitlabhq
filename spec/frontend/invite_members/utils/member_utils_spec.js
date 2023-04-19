import {
  memberName,
  triggerExternalAlert,
  qualifiesForTasksToBeDone,
} from '~/invite_members/utils/member_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { getParameterValues } from '~/lib/utils/url_utility';

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

describe('Trigger External Alert', () => {
  it('returns false', () => {
    expect(triggerExternalAlert()).toBe(false);
  });
});

describe('Qualifies For Tasks To Be Done', () => {
  it.each([
    ['invite_members_for_task', true],
    ['blah', false],
  ])(`returns name from supplied member token: %j`, (value, result) => {
    setWindowLocation(`blah/blah?open_modal=${value}`);
    getParameterValues.mockImplementation(() => {
      return [value];
    });

    expect(qualifiesForTasksToBeDone()).toBe(result);
  });
});
