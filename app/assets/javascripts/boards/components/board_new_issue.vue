<script>
import $ from 'jquery';
import { GlButton } from '@gitlab/ui';
import { getMilestone } from 'ee_else_ce/boards/boards_util';
import eventHub from '../eventhub';
import ProjectSelect from './project_select.vue';
import ListIssue from '../models/issue';
import boardsStore from '../stores/boards_store';

export default {
  name: 'BoardNewIssue',
  components: {
    ProjectSelect,
    GlButton,
  },
  props: {
    groupId: {
      type: Number,
      required: false,
      default: 0,
    },
    list: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      title: '',
      error: false,
      selectedProject: {},
    };
  },
  computed: {
    disabled() {
      if (this.groupId) {
        return this.title === '' || !this.selectedProject.name;
      }
      return this.title === '';
    },
  },
  mounted() {
    this.$refs.input.focus();
    eventHub.$on('setSelectedProject', this.setSelectedProject);
  },
  methods: {
    submit(e) {
      e.preventDefault();
      if (this.title.trim() === '') return Promise.resolve();

      this.error = false;

      const labels = this.list.label ? [this.list.label] : [];
      const assignees = this.list.assignee ? [this.list.assignee] : [];
      const milestone = getMilestone(this.list);

      const issue = new ListIssue({
        title: this.title,
        labels,
        subscribed: true,
        assignees,
        milestone,
        project_id: this.selectedProject.id,
      });

      eventHub.$emit(`scroll-board-list-${this.list.id}`);
      this.cancel();

      return this.list
        .newIssue(issue)
        .then(() => {
          // Need this because our jQuery very kindly disables buttons on ALL form submissions
          $(this.$refs.submitButton).enable();

          boardsStore.setIssueDetail(issue);
          boardsStore.setListDetail(this.list);
        })
        .catch(() => {
          // Need this because our jQuery very kindly disables buttons on ALL form submissions
          $(this.$refs.submitButton).enable();

          // Remove the issue
          this.list.removeIssue(issue);

          // Show error message
          this.error = true;
        });
    },
    cancel() {
      this.title = '';
      eventHub.$emit(`hide-issue-form-${this.list.id}`);
    },
    setSelectedProject(selectedProject) {
      this.selectedProject = selectedProject;
    },
  },
};
</script>

<template>
  <div class="board-new-issue-form">
    <div class="board-card position-relative p-3 rounded">
      <form @submit="submit($event)">
        <div v-if="error" class="flash-container">
          <div class="flash-alert">An error occurred. Please try again.</div>
        </div>
        <label :for="list.id + '-title'" class="label-bold"> Title </label>
        <input
          :id="list.id + '-title'"
          ref="input"
          v-model="title"
          class="form-control"
          type="text"
          name="issue_title"
          autocomplete="off"
        />
        <project-select v-if="groupId" :group-id="groupId" />
        <div class="clearfix prepend-top-10">
          <gl-button
            ref="submit-button"
            :disabled="disabled"
            class="float-left"
            variant="success"
            type="submit"
          >
            Submit issue
          </gl-button>
          <gl-button class="float-right" type="button" variant="default" @click="cancel">
            Cancel
          </gl-button>
        </div>
      </form>
    </div>
  </div>
</template>
