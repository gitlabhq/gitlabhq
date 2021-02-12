const createState = ({ query }) => ({
  query,
  groups: [],
  fetchingGroups: false,
  projects: [],
  fetchingProjects: false,
});
export default createState;
