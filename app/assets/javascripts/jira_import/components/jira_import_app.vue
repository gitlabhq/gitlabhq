<script>
import getJiraProjects from '../queries/getJiraProjects.query.graphql';

export default {
  name: 'JiraImportApp',
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    getJiraImports: {
      query: getJiraProjects,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update: data => data.project.jiraImports,
    },
  },
};
</script>

<template>
  <div></div>
</template>
