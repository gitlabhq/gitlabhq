import {
  memberName,
  triggerExternalAlert,
  inviteMembersTrackingOptions,
} from '~/invite_members/utils/member_utils';

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

describe('inviteMembersTrackingOptions', () => {
  it('returns options with a label', () => {
    expect(inviteMembersTrackingOptions({ label: '_label_' })).toEqual({ label: '_label_' });
  });

  it('handles options that has no label', () => {
    expect(inviteMembersTrackingOptions({})).toEqual({ label: undefined });
  });
});
