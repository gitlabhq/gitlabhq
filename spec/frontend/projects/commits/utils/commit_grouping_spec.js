import { groupCommitsByDay } from '~/projects/commits/utils/commit_grouping';

describe('groupCommitsByDay', () => {
  it.each([
    [[], 'empty input'],
    [null, 'null input'],
    [undefined, 'undefined input'],
  ])('returns empty array for %s', (input) => {
    expect(groupCommitsByDay(input)).toEqual([]);
  });

  it('groups commits by date', () => {
    const commits = [
      { id: '1', committedDate: '2025-06-23T18:00:00+00:00' },
      { id: '2', committedDate: '2025-06-23T10:00:00+00:00' },
      { id: '3', committedDate: '2025-06-21T12:00:00+00:00' },
    ];

    const result = groupCommitsByDay(commits);

    expect(result[0]).toEqual({
      day: '2025-06-23',
      isRepeatedDay: false,
      commits: [commits[0], commits[1]],
    });
    expect(result[1]).toEqual({
      day: '2025-06-21',
      isRepeatedDay: false,
      commits: [commits[2]],
    });
  });

  it('does not merge non-adjacent same-day commits, preserving git log order', () => {
    const commits = [
      { id: '3', committedDate: '2026-09-15T11:00:00+00:00' },
      { id: '2', committedDate: '2026-09-16T10:00:00+00:00' },
      { id: '1', committedDate: '2026-09-15T10:00:00+00:00' },
    ];

    const result = groupCommitsByDay(commits);

    expect(result).toEqual([
      { day: '2026-09-15', isRepeatedDay: false, commits: [commits[0]] },
      { day: '2026-09-16', isRepeatedDay: false, commits: [commits[1]] },
      { day: '2026-09-15', isRepeatedDay: true, commits: [commits[2]] },
    ]);
  });

  it('preserves commit order within each day', () => {
    const commits = [
      { id: 'first', committedDate: '2025-06-23T18:00:00+00:00' },
      { id: 'second', committedDate: '2025-06-23T10:00:00+00:00' },
    ];

    const result = groupCommitsByDay(commits);

    expect(result[0].commits[0].id).toBe('first');
    expect(result[0].commits[1].id).toBe('second');
  });

  it('falls back to the raw committedDate when it is outside the JS Date range', () => {
    const commits = [
      { id: '1', committedDate: '+292278994-08-17T07:12:55+00:00' },
      { id: '2', committedDate: '2025-06-21T12:00:00+00:00' },
    ];

    const result = groupCommitsByDay(commits);

    expect(result[0]).toEqual({
      day: '+292278994-08-17T07:12:55+00:00',
      isRepeatedDay: false,
      commits: [commits[0]],
    });
    expect(result[1]).toEqual({
      day: '2025-06-21',
      isRepeatedDay: false,
      commits: [commits[1]],
    });
  });
});
