export default () => ({
  projectId: null,
  groupId: null,
  query: '',
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
