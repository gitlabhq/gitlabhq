export default () => ({
  projectId: null,
  groupId: null,
  searchQuery: '',
  matches: {
    projectMilestones: {
      list: [],
      totalCount: 0,
      error: null,
    },
  },
  selectedMilestones: [],
  requestCount: 0,
});
