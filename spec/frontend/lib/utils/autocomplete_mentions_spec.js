import {
  extractMentionedUsernames,
  prioritizeMentionedMembers,
} from '~/lib/utils/autocomplete_mentions';

describe('extractMentionedUsernames', () => {
  it.each`
    description                         | text                            | expected
    ${'no text'}                        | ${''}                           | ${[]}
    ${'null text'}                      | ${null}                         | ${[]}
    ${'a single mention'}               | ${'hi @deloras'}                | ${['deloras']}
    ${'a mention at the start'}         | ${'@deloras hi'}                | ${['deloras']}
    ${'a trailing period'}              | ${'thanks @deloras.'}           | ${['deloras']}
    ${'a trailing comma'}               | ${'@deloras, hello'}            | ${['deloras']}
    ${'internal dots and hyphens'}      | ${'@foo.bar @foo-bar @foo_bar'} | ${['foo.bar', 'foo-bar', 'foo_bar']}
    ${'a single-character username'}    | ${'@a'}                         | ${['a']}
    ${'mentions in order of first use'} | ${'@deloras @arlie @deloras'}   | ${['deloras', 'arlie']}
    ${'mixed case, lower-cased'}        | ${'@GitLab-Security-Bot'}       | ${['gitlab-security-bot']}
  `('returns $expected for $description', ({ text, expected }) => {
    expect(extractMentionedUsernames(text)).toEqual(expected);
  });

  it('does not treat an email address as a mention', () => {
    expect(extractMentionedUsernames('reach me at deloras@example.com')).toEqual([]);
  });

  it('ignores mentions inside an inline code span', () => {
    expect(extractMentionedUsernames('see `@deloras` and @arlie')).toEqual(['arlie']);
  });

  it('ignores mentions inside a fenced code block', () => {
    expect(extractMentionedUsernames('```\n@deloras\n```\nthen @arlie')).toEqual(['arlie']);
  });

  it('ignores mentions inside a tilde-fenced code block', () => {
    expect(extractMentionedUsernames('~~~\n@deloras\n~~~\nthen @arlie')).toEqual(['arlie']);
  });
});

describe('prioritizeMentionedMembers', () => {
  const members = [{ username: 'root' }, { username: 'milford' }, { username: 'nancee_simonis' }];

  it('returns the members unchanged when nothing is mentioned', () => {
    expect(prioritizeMentionedMembers(members, [])).toBe(members);
  });

  it('floats mentioned members to the top in mention order', () => {
    expect(prioritizeMentionedMembers(members, ['nancee_simonis', 'root'])).toEqual([
      { username: 'nancee_simonis' },
      { username: 'root' },
      { username: 'milford' },
    ]);
  });

  it('matches usernames case-insensitively', () => {
    expect(prioritizeMentionedMembers(members, ['NANCEE_SIMONIS'])).toEqual([
      { username: 'nancee_simonis' },
      { username: 'root' },
      { username: 'milford' },
    ]);
  });

  it('ignores mentioned usernames that are not in the member list', () => {
    expect(prioritizeMentionedMembers(members, ['ghost'])).toEqual(members);
  });

  it('keeps members without a username among the non-prioritized group', () => {
    const withGroup = [{ username: 'root' }, { name: 'No username' }, { username: 'milford' }];

    expect(prioritizeMentionedMembers(withGroup, ['milford'])).toEqual([
      { username: 'milford' },
      { username: 'root' },
      { name: 'No username' },
    ]);
  });
});
