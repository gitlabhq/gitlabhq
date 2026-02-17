import { groupCommitsByDay } from '~/projects/commits/utils';

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
      { id: '1', authoredDate: '2025-06-23T18:00:00+00:00' },
      { id: '2', authoredDate: '2025-06-23T10:00:00+00:00' },
      { id: '3', authoredDate: '2025-06-21T12:00:00+00:00' },
    ];

    const result = groupCommitsByDay(commits);

    expect(result[0]).toEqual({
      day: '2025-06-23',
      commits: [commits[0], commits[1]],
    });
    expect(result[1]).toEqual({
      day: '2025-06-21',
      commits: [commits[2]],
    });
  });

  it('preserves commit order within each day', () => {
    const commits = [
      { id: 'first', authoredDate: '2025-06-23T18:00:00+00:00' },
      { id: 'second', authoredDate: '2025-06-23T10:00:00+00:00' },
    ];

    const result = groupCommitsByDay(commits);

    expect(result[0].commits[0].id).toBe('first');
    expect(result[0].commits[1].id).toBe('second');
  });
});
