export default () => ({
  milestonesEndpoint: '',
  labelsEndpoint: '',
  groupEndpoint: '',
  projectEndpoint: '',
  branches: {
    isLoading: false,
    errorCode: null,
    data: [],
    source: {
      selected: null,
      selectedList: [],
    },
    target: {
      selected: null,
      selectedList: [],
    },
  },
  milestones: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: null,
    selectedList: [],
  },
  labels: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: null,
    selectedList: [],
  },
  authors: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: null,
    selectedList: [],
  },
  assignees: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: null,
    selectedList: [],
  },
});
