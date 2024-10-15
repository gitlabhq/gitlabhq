import { newDate } from '~/lib/utils/datetime_utility';

/**
 * This method is to be used with `Array.prototype.sort` function
 * where array contains milestones with `due_date`/`dueDate` and/or
 * `expired` properties.
 * This method sorts given milestone params based on their expiration
 * status by putting expired milestones at the bottom and upcoming
 * milestones at the top of the list.
 *
 * @param {object} milestoneA
 * @param {object} milestoneB
 */
export function sortMilestonesByDueDate(milestoneA, milestoneB) {
  const rawDueDateA = milestoneA.due_date || milestoneA.dueDate;
  const rawDueDateB = milestoneB.due_date || milestoneB.dueDate;
  const dueDateA = rawDueDateA ? newDate(rawDueDateA) : null;
  const dueDateB = rawDueDateB ? newDate(rawDueDateB) : null;
  const expiredA = milestoneA.expired || Date.now() > dueDateA?.getTime();
  const expiredB = milestoneB.expired || Date.now() > dueDateB?.getTime();

  // Move all expired milestones to the bottom.
  if (expiredA) return 1;
  if (expiredB) return -1;

  // Move milestones without due dates just above expired milestones.
  if (!dueDateA) return 1;
  if (!dueDateB) return -1;

  // Sort by due date in ascending order.
  return dueDateA - dueDateB;
}
