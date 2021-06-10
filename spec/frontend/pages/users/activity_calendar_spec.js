import { getLevelFromContributions } from '~/pages/users/activity_calendar';

describe('getLevelFromContributions', () => {
  it.each([
    [0, 0],
    [1, 1],
    [9, 1],
    [10, 2],
    [19, 2],
    [20, 3],
    [30, 4],
    [99, 4],
  ])('.getLevelFromContributions(%i, %i)', (count, expected) => {
    expect(getLevelFromContributions(count)).toBe(expected);
  });
});
