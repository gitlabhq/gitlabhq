<script>
import {
  GlAlert,
  GlFormGroup,
  GlModal,
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlLink,
  GlSprintf,
  GlButton,
  GlFormInput,
  GlFormCheckboxGroup,
} from '@gitlab/ui';
import { partition, isString, unescape, uniqueId } from 'lodash';
import Api from '~/api';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { sanitize } from '~/lib/dompurify';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { getParameterValues } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import {
  GROUP_FILTERS,
  USERS_FILTER_ALL,
  INVITE_MEMBERS_FOR_TASK,
  MODAL_LABELS,
  LEARN_GITLAB,
} from '../constants';
import eventHub from '../event_hub';
import {
  responseMessageFromError,
  responseMessageFromSuccess,
} from '../utils/response_message_parser';
import ModalConfetti from './confetti.vue';
import GroupSelect from './group_select.vue';
import MembersTokenSelect from './members_token_select.vue';

export default {
  name: 'InviteMembersModal',
  components: {
    GlAlert,
    GlFormGroup,
    GlDatepicker,
    GlLink,
    GlModal,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlButton,
    GlFormInput,
    GlFormCheckboxGroup,
    MembersTokenSelect,
    GroupSelect,
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
    groupSelectFilter: {
      type: String,
      required: false,
      default: GROUP_FILTERS.ALL,
    },
    groupSelectParentId: {
      type: Number,
      required: false,
      default: null,
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
    helpLink: {
      type: String,
      required: true,
    },
    tasksToBeDoneOptions: {
      type: Array,
      required: true,
    },
    projects: {
      type: Array,
      required: true,
    },
    invalidGroups: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      visible: true,
      modalId: uniqueId('invite-members-modal-'),
      selectedAccessLevel: this.defaultAccessLevel,
      inviteeType: 'members',
      newUsersToInvite: [],
      selectedDate: undefined,
      selectedTasksToBeDone: [],
      selectedTaskProject: this.projects[0],
      groupToBeSharedWith: {},
      source: 'unknown',
      invalidFeedbackMessage: '',
      isLoading: false,
      mode: 'default',
    };
  },
  computed: {
    isCelebration() {
      return this.mode === 'celebrate';
    },
    validationState() {
      return this.invalidFeedbackMessage === '' ? null : false;
    },
    isInviteGroup() {
      return this.inviteeType === 'group';
    },
    modalTitle() {
      return this.$options.labels[this.inviteeType].modal[this.mode].title;
    },
    introText() {
      return sprintf(this.$options.labels[this.inviteeType][this.inviteTo][this.mode].introText, {
        name: this.name,
      });
    },
    inviteTo() {
      return this.isProject ? 'toProject' : 'toGroup';
    },
    toastOptions() {
      return {
        onComplete: () => {
          this.selectedAccessLevel = this.defaultAccessLevel;
          this.newUsersToInvite = [];
          this.groupToBeSharedWith = {};
        },
      };
    },
    basePostData() {
      return {
        expires_at: this.selectedDate,
        format: 'json',
      };
    },
    selectedRoleName() {
      return Object.keys(this.accessLevels).find(
        (key) => this.accessLevels[key] === Number(this.selectedAccessLevel),
      );
    },
    inviteDisabled() {
      return (
        this.newUsersToInvite.length === 0 && Object.keys(this.groupToBeSharedWith).length === 0
      );
    },
    errorFieldDescription() {
      if (this.inviteeType === 'group') {
        return '';
      }

      return this.$options.labels[this.inviteeType].placeHolder;
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
      this.openModal({ inviteeType: 'members', source: 'in_product_marketing_email' });
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
    openModal({ mode = 'default', inviteeType, source }) {
      this.mode = mode;
      this.inviteeType = inviteeType;
      this.source = source;

      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    trackEvent(experimentName, eventName) {
      const tracking = new ExperimentTracking(experimentName);
      tracking.event(eventName);
    },
    closeModal() {
      this.resetFields();
      this.$refs.modal.hide();
    },
    sendInvite() {
      if (this.isInviteGroup) {
        this.submitShareWithGroup();
      } else {
        this.submitInviteMembers();
      }
    },
    trackinviteMembersForTask() {
      const label = 'selected_tasks_to_be_done';
      const property = this.selectedTasksToBeDone.join(',');
      const tracking = new ExperimentTracking(INVITE_MEMBERS_FOR_TASK.name, { label, property });
      tracking.event(INVITE_MEMBERS_FOR_TASK.submit);
    },
    resetFields() {
      this.isLoading = false;
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;
      this.newUsersToInvite = [];
      this.groupToBeSharedWith = {};
      this.invalidFeedbackMessage = '';
      this.selectedTasksToBeDone = [];
      [this.selectedTaskProject] = this.projects;
    },
    changeSelectedItem(item) {
      this.selectedAccessLevel = item;
    },
    changeSelectedTaskProject(project) {
      this.selectedTaskProject = project;
    },
    submitShareWithGroup() {
      const apiShareWithGroup = this.isProject
        ? Api.projectShareWithGroup.bind(Api)
        : Api.groupShareWithGroup.bind(Api);

      apiShareWithGroup(this.id, this.shareWithGroupPostData(this.groupToBeSharedWith.id))
        .then(this.showSuccessMessage)
        .catch(this.showInvalidFeedbackMessage);
    },
    submitInviteMembers() {
      this.invalidFeedbackMessage = '';
      this.isLoading = true;

      const [usersToInviteByEmail, usersToAddById] = this.partitionNewUsersToInvite();
      const promises = [];

      if (usersToInviteByEmail !== '') {
        const apiInviteByEmail = this.isProject
          ? Api.inviteProjectMembersByEmail.bind(Api)
          : Api.inviteGroupMembersByEmail.bind(Api);

        promises.push(apiInviteByEmail(this.id, this.inviteByEmailPostData(usersToInviteByEmail)));
      }

      if (usersToAddById !== '') {
        const apiAddByUserId = this.isProject
          ? Api.addProjectMembersByUserId.bind(Api)
          : Api.addGroupMembersByUserId.bind(Api);

        promises.push(apiAddByUserId(this.id, this.addByUserIdPostData(usersToAddById)));
      }
      this.trackinviteMembersForTask();

      Promise.all(promises)
        .then(this.conditionallyShowSuccessMessage)
        .catch(this.showInvalidFeedbackMessage);
    },
    inviteByEmailPostData(usersToInviteByEmail) {
      return {
        ...this.basePostData,
        email: usersToInviteByEmail,
        access_level: this.selectedAccessLevel,
        invite_source: this.source,
        tasks_to_be_done: this.tasksToBeDoneForPost,
        tasks_project_id: this.tasksProjectForPost,
      };
    },
    addByUserIdPostData(usersToAddById) {
      return {
        ...this.basePostData,
        user_id: usersToAddById,
        access_level: this.selectedAccessLevel,
        invite_source: this.source,
        tasks_to_be_done: this.tasksToBeDoneForPost,
        tasks_project_id: this.tasksProjectForPost,
      };
    },
    shareWithGroupPostData(groupToBeSharedWith) {
      return {
        ...this.basePostData,
        group_id: groupToBeSharedWith,
        group_access: this.selectedAccessLevel,
      };
    },
    conditionallyShowSuccessMessage(response) {
      const message = this.unescapeMsg(responseMessageFromSuccess(response));

      if (message === '') {
        this.showSuccessMessage();

        return;
      }

      this.invalidFeedbackMessage = message;
      this.isLoading = false;
    },
    showSuccessMessage() {
      if (this.isOnLearnGitlab) {
        eventHub.$emit('showSuccessfulInvitationsAlert');
      } else {
        this.$toast.show(this.$options.labels.toastMessageSuccessful, this.toastOptions);
      }
      this.closeModal();
    },
    showInvalidFeedbackMessage(response) {
      const message = this.unescapeMsg(responseMessageFromError(response));

      this.isLoading = false;
      this.invalidFeedbackMessage = message || this.$options.labels.invalidFeedbackMessageDefault;
    },
    handleMembersTokenSelectClear() {
      this.invalidFeedbackMessage = '';
    },
    unescapeMsg(message) {
      return unescape(sanitize(message, { ALLOWED_TAGS: [] }));
    },
  },
  labels: MODAL_LABELS,
  membersTokenSelectLabelId: 'invite-members-input',
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    size="sm"
    data-qa-selector="invite_members_modal_content"
    data-testid="invite-members-modal"
    :title="modalTitle"
    :header-close-label="$options.labels.headerCloseLabel"
    @hidden="resetFields"
    @close="resetFields"
    @hide="resetFields"
  >
    <div>
      <div class="gl-display-flex">
        <div v-if="isCelebration" class="gl-p-4 gl-font-size-h1"><gl-emoji data-name="tada" /></div>
        <div>
          <p ref="introText">
            <gl-sprintf :message="introText">
              <template #strong="{ content }">
                <strong>{{ content }}</strong>
              </template>
            </gl-sprintf>
            <br />
            <span v-if="isCelebration">{{ $options.labels.members.modal.celebrate.intro }} </span>
            <modal-confetti v-if="isCelebration" />
          </p>
        </div>
      </div>

      <gl-form-group
        :invalid-feedback="invalidFeedbackMessage"
        :state="validationState"
        :description="errorFieldDescription"
        data-testid="members-form-group"
      >
        <label :id="$options.membersTokenSelectLabelId" class="col-form-label">{{
          $options.labels[inviteeType].searchField
        }}</label>
        <members-token-select
          v-if="!isInviteGroup"
          v-model="newUsersToInvite"
          class="gl-mb-2"
          :validation-state="validationState"
          :aria-labelledby="$options.membersTokenSelectLabelId"
          :users-filter="usersFilter"
          :filter-id="filterId"
          @clear="handleMembersTokenSelectClear"
        />
        <group-select
          v-if="isInviteGroup"
          v-model="groupToBeSharedWith"
          :access-levels="accessLevels"
          :groups-filter="groupSelectFilter"
          :parent-group-id="groupSelectParentId"
          :invalid-groups="invalidGroups"
          @input="handleMembersTokenSelectClear"
        />
      </gl-form-group>

      <label class="gl-font-weight-bold">{{ $options.labels.accessLevel }}</label>
      <div class="gl-mt-2 gl-w-half gl-xs-w-full">
        <gl-dropdown
          class="gl-shadow-none gl-w-full"
          data-qa-selector="access_level_dropdown"
          v-bind="$attrs"
          :text="selectedRoleName"
        >
          <template v-for="(key, item) in accessLevels">
            <gl-dropdown-item
              :key="key"
              active-class="is-active"
              is-check-item
              :is-checked="key === selectedAccessLevel"
              @click="changeSelectedItem(key)"
            >
              <div>{{ item }}</div>
            </gl-dropdown-item>
          </template>
        </gl-dropdown>
      </div>

      <div class="gl-mt-2 gl-w-half gl-xs-w-full">
        <gl-sprintf :message="$options.labels.readMoreText">
          <template #link="{ content }">
            <gl-link :href="helpLink" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>

      <label class="gl-mt-5 gl-display-block" for="expires_at">{{
        $options.labels.accessExpireDate
      }}</label>
      <div class="gl-mt-2 gl-w-half gl-xs-w-full gl-display-inline-block">
        <gl-datepicker
          v-model="selectedDate"
          class="gl-display-inline!"
          :min-date="new Date()"
          :target="null"
        >
          <template #default="{ formattedDate }">
            <gl-form-input
              class="gl-w-full"
              :value="formattedDate"
              :placeholder="__(`YYYY-MM-DD`)"
            />
          </template>
        </gl-datepicker>
      </div>
      <div v-if="showTasksToBeDone" data-testid="invite-members-modal-tasks-to-be-done">
        <label class="gl-mt-5">
          {{ $options.labels.members.tasksToBeDone.title }}
        </label>
        <template v-if="projects.length">
          <gl-form-checkbox-group
            v-model="selectedTasksToBeDone"
            :options="tasksToBeDoneOptions"
            data-testid="invite-members-modal-tasks"
          />
          <template v-if="showTaskProjects">
            <label class="gl-mt-5 gl-display-block">
              {{ $options.labels.members.tasksProject.title }}
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
          <gl-sprintf :message="$options.labels.members.tasksToBeDone.noProjects">
            <template #link="{ content }">
              <gl-link :href="newProjectPath" target="_blank" class="gl-label-link">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </gl-alert>
      </div>
    </div>

    <template #modal-footer>
      <gl-button data-testid="cancel-button" @click="closeModal">
        {{ $options.labels.cancelButtonText }}
      </gl-button>
      <gl-button
        :disabled="inviteDisabled"
        :loading="isLoading"
        variant="success"
        data-qa-selector="invite_button"
        data-testid="invite-button"
        @click="sendInvite"
      >
        {{ $options.labels.inviteButtonText }}
      </gl-button>
    </template>
  </gl-modal>
</template>
