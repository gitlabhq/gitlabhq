<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { getMilestone } from 'ee_else_ce/boards/boards_util';
import BoardNewIssueMixin from 'ee_else_ce/boards/mixins/board_new_issue';

import { toggleFormEventPrefix } from '../constants';
import eventHub from '../eventhub';

import BoardNewItem from './board_new_item.vue';
import ProjectSelect from './project_select.vue';

export default {
  name: 'BoardNewIssue',
  components: {
    BoardNewItem,
    ProjectSelect,
  },
  mixins: [BoardNewIssueMixin],
  inject: ['groupId'],
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['selectedProject', 'fullPath']),
    ...mapGetters(['isGroupBoard']),
    formEventPrefix() {
      return toggleFormEventPrefix.issue;
    },
    disableSubmit() {
      return this.isGroupBoard ? !this.selectedProject.name : false;
    },
    projectPath() {
      return this.isGroupBoard ? this.selectedProject.fullPath : this.fullPath;
    },
  },
  methods: {
    ...mapActions(['addListNewIssue']),
    submit({ title }) {
      const labels = this.list.label ? [this.list.label] : [];
      const assignees = this.list.assignee ? [this.list.assignee] : [];
      const milestone = getMilestone(this.list);

      return this.addListNewIssue({
        list: this.list,
        issueInput: {
          title,
          labelIds: labels?.map((l) => l.id),
          assigneeIds: assignees?.map((a) => a?.id),
          milestoneId: milestone?.id,
          projectPath: this.projectPath,
        },
      }).then(() => {
        this.cancel();
      });
    },
    cancel() {
      eventHub.$emit(`${this.formEventPrefix}${this.list.id}`);
    },
  },
};
</script>

<template>
  <board-new-item
    :list="list"
    :form-event-prefix="formEventPrefix"
    :submit-button-title="__('Create issue')"
    :disable-submit="disableSubmit"
    @form-submit="submit"
    @form-cancel="cancel"
  >
    <project-select v-if="isGroupBoard" :group-id="groupId" :list="list" />
  </board-new-item>
</template>
