<script>
import { s__ } from '~/locale';
import { getMilestone, formatIssueInput, getBoardQuery } from 'ee_else_ce/boards/boards_util';

import { setError } from '../graphql/cache_updates';

import BoardNewItem from './board_new_item.vue';
import ProjectSelect from './project_select.vue';

export default {
  name: 'BoardNewIssue',
  i18n: {
    errorFetchingBoard: s__('Boards|An error occurred while fetching board. Please try again.'),
  },
  components: {
    BoardNewItem,
    ProjectSelect,
  },
  inject: ['boardType', 'groupId', 'fullPath', 'isGroupBoard', 'isEpicBoard'],
  props: {
    list: {
      type: Object,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedProject: {},
      board: {},
    };
  },
  apollo: {
    board: {
      query() {
        return getBoardQuery(this.boardType, this.isEpicBoard);
      },
      variables() {
        return {
          fullPath: this.fullPath,
          boardId: this.boardId,
        };
      },
      update(data) {
        const { board } = data.workspace;
        return {
          ...board,
          labels: board.labels?.nodes,
        };
      },
      error(error) {
        setError({
          error,
          message: this.$options.i18n.errorFetchingBoard,
        });
      },
    },
  },
  computed: {
    disableSubmit() {
      return this.isGroupBoard ? !this.selectedProject.name : false;
    },
    projectPath() {
      return this.isGroupBoard ? this.selectedProject.fullPath : this.fullPath;
    },
  },
  methods: {
    submit({ title }) {
      const labels = this.list.label ? [this.list.label] : [];
      const assignees = this.list.assignee ? [this.list.assignee] : [];
      const milestone = getMilestone(this.list);

      return this.addNewIssueToList({
        issueInput: {
          title,
          labelIds: labels?.map((l) => l.id),
          assigneeIds: assignees?.map((a) => a?.id),
          milestoneId: milestone?.id,
          projectPath: this.projectPath,
        },
      });
    },
    addNewIssueToList({ issueInput }) {
      const { labels, assignee, milestone, weight } = this.board;
      const config = {
        labels,
        assigneeId: assignee?.id || null,
        milestoneId: milestone?.id || null,
        weight,
      };
      const input = formatIssueInput(issueInput, config);

      if (!this.isGroupBoard) {
        input.projectPath = this.fullPath;
      }

      this.$emit('addNewIssue', input);
    },
    cancel() {
      this.$emit('toggleNewForm');
    },
  },
};
</script>

<template>
  <board-new-item
    :list="list"
    :submit-button-title="__('Create issue')"
    :disable-submit="disableSubmit"
    @form-submit="submit"
    @form-cancel="cancel"
  >
    <project-select v-if="isGroupBoard" v-model="selectedProject" :list="list" />
  </board-new-item>
</template>
