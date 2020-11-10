/** Returns `true` if there is at least one in-progress request */
export const isLoading = ({ requestCount }) => requestCount > 0;

/** Returns `true` if there is a group ID and group milestones are available */
export const groupMilestonesEnabled = ({ groupId, groupMilestonesAvailable }) =>
  Boolean(groupId && groupMilestonesAvailable);
