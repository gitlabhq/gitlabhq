import { isValidDate, newDate, toISODateFormat } from '~/lib/utils/datetime_utility';

/**
 * Chunks commits into groups of consecutive commits sharing the same committed day.
 * Only adjacent commits are grouped so the git log order is preserved; a day can
 * appear more than once when the log is not strictly date-ordered.
 * @param {Array} commits - Array of commit objects with committedDate
 * @returns {Array} Array of objects with day (ISO date string), commits, and
 *   isRepeatedDay (true when the day already appeared in an earlier group)
 */
export function groupCommitsByDay(commits) {
  if (!commits?.length) return [];

  const groups = [];
  const seenDays = new Set();

  for (const commit of commits) {
    // Git permits commit timestamps with years outside JS Date's ±275,760 range
    const date = newDate(commit.committedDate);
    const day = isValidDate(date) ? toISODateFormat(date) : commit.committedDate;

    const lastGroup = groups[groups.length - 1];
    if (lastGroup?.day === day) {
      lastGroup.commits.push(commit);
    } else {
      groups.push({ day, isRepeatedDay: seenDays.has(day), commits: [commit] });
      seenDays.add(day);
    }
  }

  return groups;
}
