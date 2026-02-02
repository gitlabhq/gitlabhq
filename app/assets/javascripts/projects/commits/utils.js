/**
 * Groups commits by their authored date (day).
 * @param {Array} commits - Array of commit objects with authoredDate
 * @returns {Array} Array of objects with day (ISO date string) and commits
 */
export function groupCommitsByDay(commits) {
  if (!commits?.length) return [];

  const groupedMap = new Map();

  for (const commit of commits) {
    const day = commit.authoredDate.split('T')[0];

    if (!groupedMap.has(day)) groupedMap.set(day, { day, commits: [] });

    groupedMap.get(day).commits.push(commit);
  }

  return [...groupedMap.values()];
}
