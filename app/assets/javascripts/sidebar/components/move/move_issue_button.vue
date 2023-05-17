<script>
import ProjectSelect from '~/sidebar/components/move/issuable_move_dropdown.vue';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import moveIssueMutation from '../../queries/move_issue.mutation.graphql';

export default {
  name: 'MoveIssueButton',
  components: { ProjectSelect },
  inject: ['projectsAutocompleteEndpoint', 'projectFullPath', 'issueIid'],

  i18n: {
    title: __('Move issue'),
    titleInProgress: __('Moving issue'),
    moveErrorMessage: __('An error occurred while moving the issue.'),
  },
  data() {
    return {
      moveInProgress: false,
    };
  },
  computed: {
    dropdownButtonTitle() {
      return this.moveInProgress ? this.$options.i18n.titleInProgress : this.$options.i18n.title;
    },
  },
  methods: {
    async moveIssue(targetProject) {
      this.moveInProgress = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: moveIssueMutation,
          variables: {
            moveIssueInput: {
              projectPath: this.projectFullPath,
              iid: this.issueIid,
              targetProjectPath: targetProject.full_path,
            },
          },
        });

        if (!data.issueMove) return;

        const { errors } = data.issueMove;
        if (errors?.length > 0) {
          throw new Error(`Error moving the issue. Error message: ${errors[0].message}`);
        }

        visitUrl(data.issueMove?.issue.webUrl);
      } catch (error) {
        createAlert({
          message: this.$options.i18n.moveErrorMessage,
          captureError: true,
          error,
        });
      } finally {
        this.moveInProgress = false;
      }
    },
  },
};
</script>
<template>
  <project-select
    :projects-fetch-path="projectsAutocompleteEndpoint"
    :dropdown-button-title="dropdownButtonTitle"
    :dropdown-header-title="$options.i18n.title"
    :move-in-progress="moveInProgress"
    @move-issuable="moveIssue"
  />
</template>
