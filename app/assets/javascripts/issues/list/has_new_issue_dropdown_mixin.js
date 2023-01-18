import searchProjectsQuery from './queries/search_projects.query.graphql';

export const hasNewIssueDropdown = () => ({
  inject: ['fullPath'],
  computed: {
    newIssueDropdownQueryVariables() {
      return {
        fullPath: this.fullPath,
      };
    },
  },
  methods: {
    extractProjects(data) {
      return data?.group?.projects?.nodes;
    },
  },
  searchProjectsQuery,
});
