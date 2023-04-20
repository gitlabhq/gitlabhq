<script>
import {
  GlAlert,
  GlCollapsibleListbox,
  GlLink,
  GlSprintf,
  GlFormCheckboxGroup,
  GlButton,
  GlCollapse,
  GlIcon,
} from '@gitlab/ui';
import { partition, isString, uniqueId, isEmpty } from 'lodash';
import InviteModalBase from 'ee_else_ce/invite_members/components/invite_modal_base.vue';
import Api from '~/api';
import Tracking from '~/tracking';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { n__, sprintf } from '~/locale';
import {
  memberName,
  triggerExternalAlert,
  qualifiesForTasksToBeDone,
} from 'ee_else_ce/invite_members/utils/member_utils';
import {
  USERS_FILTER_ALL,
  INVITE_MEMBERS_FOR_TASK,
  MEMBER_MODAL_LABELS,
  INVITE_MEMBER_MODAL_TRACKING_CATEGORY,
} from '../constants';
import eventHub from '../event_hub';
import { responseFromSuccess } from '../utils/response_message_parser';
import { getInvalidFeedbackMessage } from '../utils/get_invalid_feedback_message';
import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '../utils/trigger_successful_invite_alert';
import ModalConfetti from './confetti.vue';
import MembersTokenSelect from './members_token_select.vue';
import UserLimitNotification from './user_limit_notification.vue';

export default {
  name: 'InviteMembersModal',
  components: {
    GlAlert,
    GlLink,
    GlCollapsibleListbox,
    GlSprintf,
    GlFormCheckboxGroup,
    GlButton,
    GlCollapse,
    GlIcon,
    InviteModalBase,
    MembersTokenSelect,
    ModalConfetti,
    UserLimitNotification,
    ActiveTrialNotification: () =>
      import('ee_component/invite_members/components/active_trial_notification.vue'),
  },
  mixins: [Tracking.mixin({ category: INVITE_MEMBER_MODAL_TRACKING_CATEGORY })],
  inject: ['newProjectPath'],
  props: {
    id: {
      type: String,
      required: true,
    },
    rootId: {
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
    fullPath: {
      type: String,
      required: true,
    },
    usersLimitDataset: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    activeTrialDataset: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    reloadPageOnSubmit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      invalidFeedbackMessage: '',
      isLoading: false,
      modalId: uniqueId('invite-members-modal-'),
      newUsersToInvite: [],
      invalidMembers: {},
      selectedTasksToBeDone: [],
      selectedTaskProject: this.projects[0],
      selectedTaskProjectId: this.projects[0]?.id,
      source: 'unknown',
      mode: 'default',
      // Kept in sync with "base"
      selectedAccessLevel: undefined,
      errorsLimit: 2,
      isErrorsSectionExpanded: false,
      shouldShowEmptyInvitesAlert: false,
      projectsForDropdown: this.projects.map((p) => ({ value: p.id, text: p.title, ...p })),
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
    isEmptyInvites() {
      return Boolean(this.newUsersToInvite.length);
    },
    hasInvalidMembers() {
      return !isEmpty(this.invalidMembers);
    },
    memberErrorTitle() {
      return n__(
        "InviteMembersModal|The following member couldn't be invited",
        "InviteMembersModal|The following %d members couldn't be invited",
        this.errorList.length,
      );
    },
    tasksToBeDoneEnabled() {
      return qualifiesForTasksToBeDone(this.source) && this.tasksToBeDoneOptions.length;
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
    showUserLimitNotification() {
      return !isEmpty(this.usersLimitDataset.alertVariant);
    },
    limitVariant() {
      return this.usersLimitDataset.alertVariant;
    },
    errorList() {
      return Object.entries(this.invalidMembers).map(([member, error]) => {
        return { member, displayedMemberName: this.tokenName(member), message: error };
      });
    },
    errorsLimited() {
      return this.errorList.slice(0, this.errorsLimit);
    },
    errorsExpanded() {
      return this.errorList.slice(this.errorsLimit);
    },
    shouldErrorsSectionExpand() {
      return Boolean(this.errorsExpanded.length);
    },
    errorCollapseText() {
      if (this.isErrorsSectionExpanded) {
        return this.$options.labels.expandedErrors;
      }

      return sprintf(this.$options.labels.collapsedErrors, {
        count: this.errorsExpanded.length,
      });
    },
    formGroupDescription() {
      return this.invalidFeedbackMessage ? null : this.$options.labels.placeHolder;
    },
  },
  watch: {
    isEmptyInvites: {
      handler(updatedValue) {
        // nothing to do if the invites are **still** empty and the emptyInvites were never set from submit
        if (!updatedValue && !this.shouldShowEmptyInvitesAlert) {
          return;
        }

        this.clearEmptyInviteError();
      },
    },
  },
  mounted() {
    if (this.reloadPageOnSubmit) {
      displaySuccessfulInvitationAlert();
    }

    eventHub.$on('openModal', (options) => {
      this.openModal(options);
    });

    if (this.tasksToBeDoneEnabled) {
      this.openModal({ source: 'in_product_marketing_email' });
    }
  },
  methods: {
    showInvalidFeedbackMessage(response) {
      this.invalidFeedbackMessage = getInvalidFeedbackMessage(response);
    },
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
    openModal({ mode = 'default', source = 'unknown' }) {
      this.mode = mode;
      this.source = source;

      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
      this.track('render', { label: this.source });
    },
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    showEmptyInvitesAlert() {
      this.invalidFeedbackMessage = this.$options.labels.placeHolder;
      this.shouldShowEmptyInvitesAlert = true;
      this.$refs.alerts.focus();
    },
    getInvitePayload({ accessLevel, expiresAt }) {
      const [usersToInviteByEmail, usersToAddById] = this.partitionNewUsersToInvite();

      const email = usersToInviteByEmail !== '' ? { email: usersToInviteByEmail } : {};
      const userId = usersToAddById !== '' ? { user_id: usersToAddById } : {};

      return {
        format: 'json',
        expires_at: expiresAt,
        access_level: accessLevel,
        invite_source: this.source,
        tasks_to_be_done: this.tasksToBeDoneForPost,
        tasks_project_id: this.tasksProjectForPost,
        ...email,
        ...userId,
      };
    },
    async sendInvite({ accessLevel, expiresAt }) {
      this.isLoading = true;
      this.clearValidation();

      if (!this.isEmptyInvites) {
        this.showEmptyInvitesAlert();
        return;
      }

      this.trackInviteMembersForTask();

      const apiAddByInvite = this.isProject
        ? Api.inviteProjectMembers.bind(Api)
        : Api.inviteGroupMembers.bind(Api);

      try {
        const payload = this.getInvitePayload({ accessLevel, expiresAt });
        const response = await apiAddByInvite(this.id, payload);

        const { error, message } = responseFromSuccess(response);

        if (error) {
          this.showMemberErrors(message);
        } else {
          this.onInviteSuccess();
        }
      } catch (e) {
        this.showInvalidFeedbackMessage(e);
      } finally {
        this.isLoading = false;
      }
    },
    showMemberErrors(message) {
      this.invalidMembers = message;
      this.$refs.alerts.focus();
    },
    tokenName(username) {
      // initial token creation hits this and nothing is found... so safe navigation
      return this.newUsersToInvite.find((member) => memberName(member) === username)?.name;
    },
    trackInviteMembersForTask() {
      const label = 'selected_tasks_to_be_done';
      const property = this.selectedTasksToBeDone.join(',');
      this.track(INVITE_MEMBERS_FOR_TASK.submit, { label, property });
    },
    onCancel() {
      this.track('click_cancel', { label: this.source });
    },
    onClose() {
      this.track('click_x', { label: this.source });
    },
    resetFields() {
      this.clearValidation();
      this.isLoading = false;
      this.shouldShowEmptyInvitesAlert = false;
      this.newUsersToInvite = [];
      this.selectedTasksToBeDone = [];
      [this.selectedTaskProject] = this.projects;
    },
    changeSelectedTaskProject(projectId) {
      this.selectedTaskProject = this.projects.find((project) => project.id === projectId);
    },
    onInviteSuccess() {
      this.track('invite_successful', { label: this.source });

      if (this.reloadPageOnSubmit) {
        reloadOnInvitationSuccess();
      } else {
        this.showSuccessMessage();
      }
    },
    showSuccessMessage() {
      if (!triggerExternalAlert(this.source)) {
        this.$toast.show(this.$options.labels.toastMessageSuccessful);
      }

      this.closeModal();
    },
    onAccessLevelUpdate(val) {
      this.selectedAccessLevel = val;
    },
    clearValidation() {
      this.invalidFeedbackMessage = '';
      this.invalidMembers = {};
    },
    clearEmptyInviteError() {
      this.invalidFeedbackMessage = '';
      this.shouldShowEmptyInvitesAlert = false;
    },
    removeToken(token) {
      delete this.invalidMembers[memberName(token)];
      this.invalidMembers = { ...this.invalidMembers };
    },
    toggleErrorExpansion() {
      this.isErrorsSectionExpanded = !this.isErrorsSectionExpanded;
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
    :form-group-description="formGroupDescription"
    :invalid-feedback-message="invalidFeedbackMessage"
    :is-loading="isLoading"
    :new-users-to-invite="newUsersToInvite"
    :root-group-id="rootId"
    :users-limit-dataset="usersLimitDataset"
    :full-path="fullPath"
    @close="onClose"
    @cancel="onCancel"
    @reset="resetFields"
    @submit="sendInvite"
    @access-level="onAccessLevelUpdate"
  >
    <template #intro-text-before>
      <div v-if="isCelebration" class="gl-p-4 gl-font-size-h1">
        <gl-emoji data-name="tada" />
      </div>
    </template>
    <template #intro-text-after>
      <br />
      <span v-if="isCelebration">{{ $options.labels.modal.celebrate.intro }} </span>
      <modal-confetti v-if="isCelebration" />
    </template>

    <template #alert>
      <div ref="alerts" tabindex="-1">
        <gl-alert
          v-if="shouldShowEmptyInvitesAlert"
          id="empty-invites-alert"
          class="gl-mb-4"
          variant="danger"
          :dismissible="false"
          data-testid="empty-invites-alert"
        >
          {{ $options.labels.emptyInvitesAlertText }}
        </gl-alert>
        <gl-alert
          v-if="hasInvalidMembers"
          class="gl-mb-4"
          variant="danger"
          :dismissible="false"
          :title="memberErrorTitle"
          data-testid="alert-member-error"
        >
          {{ $options.labels.memberErrorListText }}
          <ul class="gl-pl-5 gl-mb-0">
            <li
              v-for="error in errorsLimited"
              :key="error.member"
              data-testid="errors-limited-item"
            >
              <strong>{{ error.displayedMemberName }}:</strong> {{ error.message }}
            </li>
          </ul>
          <template v-if="shouldErrorsSectionExpand">
            <gl-collapse v-model="isErrorsSectionExpanded">
              <ul class="gl-pl-5 gl-mb-0">
                <li
                  v-for="error in errorsExpanded"
                  :key="error.member"
                  data-testid="errors-expanded-item"
                >
                  <strong>{{ error.displayedMemberName }}:</strong> {{ error.message }}
                </li>
              </ul>
            </gl-collapse>
            <gl-button
              class="gl-text-decoration-none! gl-shadow-none! gl-mt-3"
              data-testid="accordion-button"
              variant="link"
              @click="toggleErrorExpansion"
            >
              {{ errorCollapseText }}
              <gl-icon
                name="chevron-down"
                class="gl-transition-medium"
                :class="{ 'gl-rotate-180': isErrorsSectionExpanded }"
              />
            </gl-button>
          </template>
        </gl-alert>
        <user-limit-notification
          v-else-if="showUserLimitNotification"
          class="gl-mb-5"
          :limit-variant="limitVariant"
          :users-limit-dataset="usersLimitDataset"
        />
      </div>
    </template>

    <template #active-trial-alert>
      <active-trial-notification v-if="!isCelebration" :active-trial-dataset="activeTrialDataset" />
    </template>

    <template #select="{ exceptionState, inputId }">
      <members-token-select
        v-model="newUsersToInvite"
        class="gl-mb-2"
        aria-labelledby="empty-invites-alert"
        :input-id="inputId"
        :exception-state="exceptionState"
        :users-filter="usersFilter"
        :filter-id="filterId"
        :invalid-members="invalidMembers"
        @clear="clearValidation"
        @token-remove="removeToken"
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
            <gl-collapsible-listbox
              v-model="selectedTaskProjectId"
              :items="projectsForDropdown"
              :block="true"
              class="gl-w-half gl-xs-w-full"
              data-testid="invite-members-modal-project-select"
              @select="changeSelectedTaskProject"
            />
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
