<script>
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlLink,
  GlSprintf,
  GlFormCheckboxGroup,
} from '@gitlab/ui';
import { partition, isString, uniqueId } from 'lodash';
import Api from '~/api';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { getParameterValues } from '~/lib/utils/url_utility';
import {
  USERS_FILTER_ALL,
  INVITE_MEMBERS_FOR_TASK,
  MEMBER_MODAL_LABELS,
  LEARN_GITLAB,
} from '../constants';
import eventHub from '../event_hub';
import { responseMessageFromSuccess } from '../utils/response_message_parser';
import ModalConfetti from './confetti.vue';
import InviteModalBase from './invite_modal_base.vue';
import MembersTokenSelect from './members_token_select.vue';

export default {
  name: 'InviteMembersModal',
  components: {
    GlAlert,
    GlLink,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlFormCheckboxGroup,
    InviteModalBase,
    MembersTokenSelect,
    ModalConfetti,
  },
  inject: ['newProjectPath'],
  props: {
    id: {
      type: String,
      required: true,
    },
    isProject: {
      type: Boolean,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    accessLevels: {
      type: Object,
      required: true,
    },
    defaultAccessLevel: {
      type: Number,
      required: true,
    },
    helpLink: {
      type: String,
      required: true,
    },
    usersFilter: {
      type: String,
      required: false,
      default: USERS_FILTER_ALL,
    },
    filterId: {
      type: Number,
      required: false,
      default: null,
    },
    tasksToBeDoneOptions: {
      type: Array,
      required: true,
    },
    projects: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      modalId: uniqueId('invite-members-modal-'),
      newUsersToInvite: [],
      selectedTasksToBeDone: [],
      selectedTaskProject: this.projects[0],
      source: 'unknown',
      mode: 'default',
      // Kept in sync with "base"
      selectedAccessLevel: undefined,
    };
  },
  computed: {
    isCelebration() {
      return this.mode === 'celebrate';
    },
    modalTitle() {
      return this.$options.labels.modal[this.mode].title;
    },
    inviteTo() {
      return this.isProject ? 'toProject' : 'toGroup';
    },
    labelIntroText() {
      return this.$options.labels[this.inviteTo][this.mode].introText;
    },
    inviteDisabled() {
      return this.newUsersToInvite.length === 0;
    },
    tasksToBeDoneEnabled() {
      return (
        (getParameterValues('open_modal')[0] === 'invite_members_for_task' ||
          this.isOnLearnGitlab) &&
        this.tasksToBeDoneOptions.length
      );
    },
    showTasksToBeDone() {
      return (
        this.tasksToBeDoneEnabled &&
        this.selectedAccessLevel >= INVITE_MEMBERS_FOR_TASK.minimum_access_level
      );
    },
    showTaskProjects() {
      return !this.isProject && this.selectedTasksToBeDone.length;
    },
    tasksToBeDoneForPost() {
      return this.showTasksToBeDone ? this.selectedTasksToBeDone : [];
    },
    tasksProjectForPost() {
      return this.showTasksToBeDone && this.selectedTasksToBeDone.length
        ? this.selectedTaskProject.id
        : '';
    },
    isOnLearnGitlab() {
      return this.source === LEARN_GITLAB;
    },
  },
  mounted() {
    eventHub.$on('openModal', (options) => {
      this.openModal(options);
      if (this.isOnLearnGitlab) {
        this.trackEvent(INVITE_MEMBERS_FOR_TASK.name, this.source);
      }
    });

    if (this.tasksToBeDoneEnabled) {
      this.openModal({ source: 'in_product_marketing_email' });
      this.trackEvent(INVITE_MEMBERS_FOR_TASK.name, INVITE_MEMBERS_FOR_TASK.view);
    }
  },
  methods: {
    partitionNewUsersToInvite() {
      const [usersToInviteByEmail, usersToAddById] = partition(
        this.newUsersToInvite,
        (user) => isString(user.id) && user.id.includes('user-defined-token'),
      );

      return [
        usersToInviteByEmail.map((user) => user.name).join(','),
        usersToAddById.map((user) => user.id).join(','),
      ];
    },
    openModal({ mode = 'default', source }) {
      this.mode = mode;
      this.source = source;

      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    trackEvent(experimentName, eventName) {
      const tracking = new ExperimentTracking(experimentName);
      tracking.event(eventName);
    },
    sendInvite({ onError, onSuccess, data: { accessLevel, expiresAt } }) {
      const [usersToInviteByEmail, usersToAddById] = this.partitionNewUsersToInvite();
      const promises = [];
      const baseData = {
        format: 'json',
        expires_at: expiresAt,
        access_level: accessLevel,
        invite_source: this.source,
        tasks_to_be_done: this.tasksToBeDoneForPost,
        tasks_project_id: this.tasksProjectForPost,
      };

      if (usersToInviteByEmail !== '') {
        const apiInviteByEmail = this.isProject
          ? Api.inviteProjectMembersByEmail.bind(Api)
          : Api.inviteGroupMembersByEmail.bind(Api);

        promises.push(
          apiInviteByEmail(this.id, {
            ...baseData,
            email: usersToInviteByEmail,
          }),
        );
      }

      if (usersToAddById !== '') {
        const apiAddByUserId = this.isProject
          ? Api.addProjectMembersByUserId.bind(Api)
          : Api.addGroupMembersByUserId.bind(Api);

        promises.push(
          apiAddByUserId(this.id, {
            ...baseData,
            user_id: usersToAddById,
          }),
        );
      }
      this.trackinviteMembersForTask();

      Promise.all(promises)
        .then((responses) => {
          const message = responseMessageFromSuccess(responses);

          if (message) {
            onError({
              response: {
                data: {
                  message,
                },
              },
            });
          } else {
            onSuccess();
            this.showSuccessMessage();
          }
        })
        .catch(onError);
    },
    trackinviteMembersForTask() {
      const label = 'selected_tasks_to_be_done';
      const property = this.selectedTasksToBeDone.join(',');
      const tracking = new ExperimentTracking(INVITE_MEMBERS_FOR_TASK.name, { label, property });
      tracking.event(INVITE_MEMBERS_FOR_TASK.submit);
    },
    resetFields() {
      this.newUsersToInvite = [];
      this.selectedTasksToBeDone = [];
      [this.selectedTaskProject] = this.projects;
    },
    changeSelectedTaskProject(project) {
      this.selectedTaskProject = project;
    },
    showSuccessMessage() {
      if (this.isOnLearnGitlab) {
        eventHub.$emit('showSuccessfulInvitationsAlert');
      } else {
        this.$toast.show(this.$options.labels.toastMessageSuccessful);
      }

      this.closeModal();
    },
    onAccessLevelUpdate(val) {
      this.selectedAccessLevel = val;
    },
  },
  labels: MEMBER_MODAL_LABELS,
};
</script>
<template>
  <invite-modal-base
    :modal-id="modalId"
    :modal-title="modalTitle"
    :name="name"
    :access-levels="accessLevels"
    :default-access-level="defaultAccessLevel"
    :help-link="helpLink"
    :label-intro-text="labelIntroText"
    :label-search-field="$options.labels.searchField"
    :form-group-description="$options.labels.placeHolder"
    :submit-disabled="inviteDisabled"
    @reset="resetFields"
    @submit="sendInvite"
    @access-level="onAccessLevelUpdate"
  >
    <template #intro-text-before>
      <div v-if="isCelebration" class="gl-p-4 gl-font-size-h1"><gl-emoji data-name="tada" /></div>
    </template>
    <template #intro-text-after>
      <br />
      <span v-if="isCelebration">{{ $options.labels.modal.celebrate.intro }} </span>
      <modal-confetti v-if="isCelebration" />
    </template>
    <template #select="{ clearValidation, validationState, labelId }">
      <members-token-select
        v-model="newUsersToInvite"
        class="gl-mb-2"
        :validation-state="validationState"
        :aria-labelledby="labelId"
        :users-filter="usersFilter"
        :filter-id="filterId"
        @clear="clearValidation"
      />
    </template>
    <template #form-after>
      <div v-if="showTasksToBeDone" data-testid="invite-members-modal-tasks-to-be-done">
        <label class="gl-mt-5">
          {{ $options.labels.tasksToBeDone.title }}
        </label>
        <template v-if="projects.length">
          <gl-form-checkbox-group
            v-model="selectedTasksToBeDone"
            :options="tasksToBeDoneOptions"
            data-testid="invite-members-modal-tasks"
          />
          <template v-if="showTaskProjects">
            <label class="gl-mt-5 gl-display-block">
              {{ $options.labels.tasksProject.title }}
            </label>
            <gl-dropdown
              class="gl-w-half gl-xs-w-full"
              :text="selectedTaskProject.title"
              data-testid="invite-members-modal-project-select"
            >
              <template v-for="project in projects">
                <gl-dropdown-item
                  :key="project.id"
                  active-class="is-active"
                  is-check-item
                  :is-checked="project.id === selectedTaskProject.id"
                  @click="changeSelectedTaskProject(project)"
                >
                  {{ project.title }}
                </gl-dropdown-item>
              </template>
            </gl-dropdown>
          </template>
        </template>
        <gl-alert
          v-else-if="tasksToBeDoneEnabled"
          variant="tip"
          :dismissible="false"
          data-testid="invite-members-modal-no-projects-alert"
        >
          <gl-sprintf :message="$options.labels.tasksToBeDone.noProjects">
            <template #link="{ content }">
              <gl-link :href="newProjectPath" target="_blank" class="gl-label-link">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </gl-alert>
      </div>
    </template>
  </invite-modal-base>
</template>
