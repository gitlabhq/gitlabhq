<script>
import { GlButton } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { getMilestone } from 'ee_else_ce/boards/boards_util';
import ListIssue from 'ee_else_ce/boards/models/issue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import eventHub from '../eventhub';
import boardsStore from '../stores/boards_store';
import ProjectSelect from './project_select_deprecated.vue';

// This component is being replaced in favor of './board_new_issue.vue' for GraphQL boards

export default {
  name: 'BoardNewIssueDeprecated',
  components: {
    ProjectSelect,
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['groupId'],
  props: {
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
    ...mapGetters(['isGroupBoard']),
    disabled() {
      if (this.isGroupBoard) {
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

      const { weightFeatureAvailable } = boardsStore;
      const { weight } = weightFeatureAvailable ? boardsStore.state.currentBoard : {};

      const issue = new ListIssue({
        title: this.title,
        labels,
        subscribed: true,
        assignees,
        milestone,
        project_id: this.selectedProject.id,
        weight,
      });

      eventHub.$emit(`scroll-board-list-${this.list.id}`);
      this.cancel();

      return this.list
        .newIssue(issue)
        .then(() => {
          boardsStore.setIssueDetail(issue);
          boardsStore.setListDetail(this.list);
        })
        .catch(() => {
          this.list.removeIssue(issue);

          // Show error message
          this.error = true;
        });
    },
    cancel() {
      this.title = '';
      eventHub.$emit(`toggle-issue-form-${this.list.id}`);
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
          <div class="flash-alert">{{ __('An error occurred. Please try again.') }}</div>
        </div>
        <label :for="list.id + '-title'" class="label-bold">{{ __('Title') }}</label>
        <input
          :id="list.id + '-title'"
          ref="input"
          v-model="title"
          class="form-control"
          type="text"
          name="issue_title"
          autocomplete="off"
        />
        <project-select v-if="isGroupBoard" :group-id="groupId" :list="list" />
        <div class="clearfix gl-mt-3">
          <gl-button
            ref="submitButton"
            :disabled="disabled"
            class="float-left js-no-auto-disable"
            variant="success"
            category="primary"
            type="submit"
            >{{ __('Create issue') }}</gl-button
          >
          <gl-button
            ref="cancelButton"
            class="float-right"
            type="button"
            variant="default"
            @click="cancel"
            >{{ __('Cancel') }}</gl-button
          >
        </div>
      </form>
    </div>
  </div>
</template>
