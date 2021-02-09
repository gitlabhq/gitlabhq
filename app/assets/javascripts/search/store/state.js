const createState = ({ query }) => ({
  query,
  groups: [],
  fetchingGroups: false,
  projects: [],
  fetchingProjects: false,
  inflatedScopeTabs: [],
});
export default createState;
