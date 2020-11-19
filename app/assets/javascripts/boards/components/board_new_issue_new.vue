<script>
import { mapActions } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { getMilestone } from 'ee_else_ce/boards/boards_util';
import eventHub from '../eventhub';
import ProjectSelect from './project_select.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __ } from '~/locale';

export default {
  name: 'BoardNewIssue',
  i18n: {
    submit: __('Submit issue'),
    cancel: __('Cancel'),
  },
  components: {
    ProjectSelect,
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  inject: ['groupId', 'weightFeatureAvailable', 'boardWeight'],
  data() {
    return {
      title: '',
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
    inputFieldId() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${this.list.id}-title`;
    },
  },
  mounted() {
    this.$refs.input.focus();
    eventHub.$on('setSelectedProject', this.setSelectedProject);
  },
  methods: {
    ...mapActions(['addListNewIssue']),
    submit(e) {
      e.preventDefault();

      const labels = this.list.label ? [this.list.label] : [];
      const assignees = this.list.assignee ? [this.list.assignee] : [];
      const milestone = getMilestone(this.list);

      const weight = this.weightFeatureAvailable ? this.boardWeight : undefined;

      const { title } = this;

      eventHub.$emit(`scroll-board-list-${this.list.id}`);

      return this.addListNewIssue({
        issueInput: {
          title,
          labelIds: labels?.map(l => l.id),
          assigneeIds: assignees?.map(a => a?.id),
          milestoneId: milestone?.id,
          projectPath: this.selectedProject.path,
          weight: weight >= 0 ? weight : null,
        },
        list: this.list,
      }).then(() => {
        this.reset();
      });
    },
    reset() {
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
      <form ref="submitForm" @submit="submit">
        <label :for="inputFieldId" class="label-bold">{{ __('Title') }}</label>
        <input
          :id="inputFieldId"
          ref="input"
          v-model="title"
          class="form-control"
          type="text"
          name="issue_title"
          autocomplete="off"
        />
        <project-select v-if="groupId" :group-id="groupId" :list="list" />
        <div class="clearfix gl-mt-3">
          <gl-button
            ref="submitButton"
            :disabled="disabled"
            class="float-left js-no-auto-disable"
            variant="success"
            category="primary"
            type="submit"
          >
            {{ $options.i18n.submit }}
          </gl-button>
          <gl-button
            ref="cancelButton"
            class="float-right"
            type="button"
            variant="default"
            @click="reset"
          >
            {{ $options.i18n.cancel }}
          </gl-button>
        </div>
      </form>
    </div>
  </div>
</template>
