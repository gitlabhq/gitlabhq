<script>
import { GlAlert } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { logError } from '~/lib/logger';
import { s__ } from '~/locale';
import {
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
} from '~/work_items/constants';
import issuableEventHub from '~/issues/list/eventhub';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
import moveIssueMutation from '../../queries/move_issue.mutation.graphql';
import IssuableMoveDropdown from './issuable_move_dropdown.vue';

export default {
  name: 'MoveIssuesButton',
  components: {
    IssuableMoveDropdown,
    GlAlert,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    projectsFetchPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedIssuables: [],
      moveInProgress: false,
    };
  },
  computed: {
    cannotMoveTasksWarningTitle() {
      if (this.tasksSelected && this.testCasesSelected) {
        return s__('Issues|Tasks and test cases can not be moved.');
      }

      if (this.testCasesSelected) {
        return s__('Issues|Test cases can not be moved.');
      }

      return s__('Issues|Tasks can not be moved.');
    },
    issuesSelected() {
      return this.selectedIssuables.some((item) => item.type === WORK_ITEM_TYPE_ENUM_ISSUE);
    },
    incidentsSelected() {
      return this.selectedIssuables.some((item) => item.type === WORK_ITEM_TYPE_ENUM_INCIDENT);
    },
    tasksSelected() {
      return this.selectedIssuables.some((item) => item.type === WORK_ITEM_TYPE_ENUM_TASK);
    },
    testCasesSelected() {
      return this.selectedIssuables.some((item) => item.type === WORK_ITEM_TYPE_ENUM_TEST_CASE);
    },
  },
  mounted() {
    issuableEventHub.$on('issuables:issuableChecked', this.handleIssuableChecked);
  },
  beforeDestroy() {
    issuableEventHub.$off('issuables:issuableChecked', this.handleIssuableChecked);
  },
  methods: {
    handleIssuableChecked(issuable, value) {
      if (value) {
        this.selectedIssuables.push(issuable);
      } else {
        const index = this.selectedIssuables.indexOf(issuable);
        if (index > -1) {
          this.selectedIssuables.splice(index, 1);
        }
      }
    },
    moveIssues(targetProject) {
      const iids = this.selectedIssuables.reduce((result, issueData) => {
        if (
          issueData.type === WORK_ITEM_TYPE_ENUM_ISSUE ||
          issueData.type === WORK_ITEM_TYPE_ENUM_INCIDENT
        ) {
          result.push(issueData.iid);
        }
        return result;
      }, []);

      if (iids.length === 0) {
        return;
      }

      this.moveInProgress = true;
      issuableEventHub.$emit('issuables:bulkMoveStarted');

      const promises = iids.map((id) => {
        return this.moveIssue(id, targetProject);
      });

      Promise.all(promises)
        .then((promisesResult) => {
          let foundError = false;

          for (const promiseResult of promisesResult) {
            if (promiseResult.data.issueMove?.errors?.length) {
              foundError = true;
              logError(
                `Error moving issue. Error message: ${promiseResult.data.issueMove.errors[0].message}`,
              );
            }
          }

          if (!foundError) {
            const client = this.$apollo.provider.defaultClient;
            client.refetchQueries({
              include: [getIssuesQuery, getIssuesCountQuery],
            });
            this.moveInProgress = false;
            this.selectedIssuables = [];
            issuableEventHub.$emit('issuables:bulkMoveEnded');
          } else {
            throw new Error();
          }
        })
        .catch(() => {
          this.moveInProgress = false;
          issuableEventHub.$emit('issuables:bulkMoveEnded');

          createAlert({
            message: s__(`Issues|There was an error while moving the issues.`),
          });
        });
    },
    moveIssue(issueIid, targetProject) {
      return this.$apollo.mutate({
        mutation: moveIssueMutation,
        variables: {
          moveIssueInput: {
            projectPath: this.projectFullPath,
            iid: issueIid,
            targetProjectPath: targetProject.full_path,
          },
        },
      });
    },
  },
  i18n: {
    dropdownButtonTitle: s__('Issues|Move selected'),
  },
};
</script>
<template>
  <div>
    <issuable-move-dropdown
      :project-full-path="projectFullPath"
      :projects-fetch-path="projectsFetchPath"
      :move-in-progress="moveInProgress"
      :disabled="!issuesSelected && !incidentsSelected"
      :dropdown-header-title="$options.i18n.dropdownButtonTitle"
      :dropdown-button-title="$options.i18n.dropdownButtonTitle"
      @move-issuable="moveIssues"
    />
    <gl-alert v-if="tasksSelected || testCasesSelected" :dismissible="false" variant="warning">
      {{ cannotMoveTasksWarningTitle }}
    </gl-alert>
  </div>
</template>
