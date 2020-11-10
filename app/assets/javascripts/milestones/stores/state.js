export default () => ({
  projectId: null,
  groupId: null,
  groupMilestonesAvailable: false,
  searchQuery: '',
  matches: {
    projectMilestones: {
      list: [],
      totalCount: 0,
      error: null,
    },
    groupMilestones: {
      list: [],
      totalCount: 0,
      error: null,
    },
  },
  selectedMilestones: [],
  requestCount: 0,
});
