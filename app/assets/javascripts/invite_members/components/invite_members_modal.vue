<script>
import { GlAlert, GlButton, GlCollapse, GlIcon } from '@gitlab/ui';
import { partition, isString, uniqueId, isEmpty } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import InviteModalBase from 'ee_else_ce/invite_members/components/invite_modal_base.vue';
import Api from '~/api';
import Tracking from '~/tracking';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { n__, sprintf } from '~/locale';
import { memberName, triggerExternalAlert } from 'ee_else_ce/invite_members/utils/member_utils';
import { responseFromSuccess } from 'ee_else_ce/invite_members/utils/response_message_parser';
import { captureException } from '~/ci/runner/sentry_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  BLOCKED_SEAT_OVERAGES_ERROR_REASON,
  BLOCKED_SEAT_OVERAGES_BODY,
  BLOCKED_SEAT_OVERAGES_CTA,
  BLOCKED_SEAT_OVERAGES_CTA_DOCS,
  USERS_FILTER_ALL,
  MEMBER_MODAL_LABELS,
  INVITE_MEMBER_MODAL_TRACKING_CATEGORY,
} from '../constants';
import eventHub from '../event_hub';
import { getInvalidFeedbackMessage } from '../utils/get_invalid_feedback_message';
import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
  markLocalStorageForQueuedAlert,
} from '../utils/trigger_successful_invite_alert';
import ModalConfetti from './confetti.vue';
import MembersTokenSelect from './members_token_select.vue';
import UserLimitNotification from './user_limit_notification.vue';

export default {
  name: 'InviteMembersModal',
  components: {
    GlAlert,
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
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin({ category: INVITE_MEMBER_MODAL_TRACKING_CATEGORY })],
  inject: {
    addSeatsHref: {
      default: '',
    },
    hasBsoEnabled: {
      default: false,
    },
  },
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
    defaultMemberRoleId: {
      type: Number,
      required: false,
      default: null,
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
      errorReason: '',
      invalidFeedbackMessage: '',
      isLoading: false,
      modalId: uniqueId('invite-members-modal-'),
      newUsersToInvite: [],
      usersWithWarning: {},
      invalidMembers: {},
      source: 'unknown',
      mode: 'default',
      errorsLimit: 2,
      isErrorsSectionExpanded: false,
      shouldShowEmptyInvitesAlert: false,
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
    accessExpirationHelpLink() {
      return this.isProject
        ? helpPagePath('user/project/members/_index', { anchor: 'add-users-to-a-project' })
        : helpPagePath('user/group/_index', { anchor: 'add-users-to-a-group' });
    },
    isEmptyInvites() {
      return Boolean(this.newUsersToInvite.length);
    },
    hasUsersWithWarning() {
      return !isEmpty(this.usersWithWarning);
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
    showUserLimitNotification() {
      return !isEmpty(this.usersLimitDataset.alertVariant);
    },
    staticRoles() {
      return { validRoles: this.accessLevels };
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
    shouldShowSeatOverageNotification() {
      return this.errorReason === BLOCKED_SEAT_OVERAGES_ERROR_REASON && this.addSeatsHref;
    },
    primaryButtonText() {
      return this.hasBsoEnabled ? BLOCKED_SEAT_OVERAGES_CTA_DOCS : BLOCKED_SEAT_OVERAGES_CTA;
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
    getInvitePayload({ accessLevel, expiresAt, memberRoleId }) {
      const [usersToInviteByEmail, usersToAddById] = this.partitionNewUsersToInvite();

      const email = usersToInviteByEmail !== '' ? { email: usersToInviteByEmail } : {};
      const userId = usersToAddById !== '' ? { user_id: usersToAddById } : {};

      return {
        format: 'json',
        expires_at: expiresAt,
        access_level: accessLevel,
        member_role_id: memberRoleId,
        invite_source: this.source,
        ...email,
        ...userId,
      };
    },
    async sendInvite({ accessLevel, expiresAt, memberRoleId }) {
      this.isLoading = true;
      this.clearValidation();

      if (!this.isEmptyInvites) {
        this.showEmptyInvitesAlert();
        return;
      }

      const apiAddByInvite = this.isProject
        ? Api.inviteProjectMembers.bind(Api)
        : Api.inviteGroupMembers.bind(Api);

      try {
        const payload = this.getInvitePayload({ accessLevel, expiresAt, memberRoleId });
        const response = await apiAddByInvite(this.id, payload);

        const { error, message, usersWithWarning } = responseFromSuccess(response);

        this.usersWithWarning = usersWithWarning;

        if (error) {
          this.errorReason = response.data.reason;
          this.showErrors(message);
        } else if (this.hasUsersWithWarning) {
          markLocalStorageForQueuedAlert();
        } else if (!this.hasInvalidMembers) {
          this.onInviteSuccess();
        }
      } catch (error) {
        captureException({ error, component: this.$options.name });
        this.showInvalidFeedbackMessage(error);
      } finally {
        this.isLoading = false;
      }
    },
    showErrors(message) {
      if (isString(message)) {
        this.invalidFeedbackMessage = message;
      } else {
        this.invalidMembers = message;
        this.$refs.alerts.focus();
      }
    },
    tokenName(username) {
      // initial token creation hits this and nothing is found... so safe navigation
      return this.newUsersToInvite.find((member) => memberName(member) === username)?.name;
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
    clearValidation() {
      this.errorReason = '';
      this.invalidFeedbackMessage = '';
      this.usersWithWarning = {};
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
  i18n: {
    BLOCKED_SEAT_OVERAGES_BODY,
  },
};
</script>
<template>
  <invite-modal-base
    :modal-id="modalId"
    :modal-title="modalTitle"
    :name="name"
    :access-levels="staticRoles"
    :default-access-level="defaultAccessLevel"
    :default-member-role-id="defaultMemberRoleId"
    :help-link="helpLink"
    :access-expiration-help-link="accessExpirationHelpLink"
    :label-intro-text="labelIntroText"
    :label-search-field="$options.labels.searchField"
    :form-group-description="formGroupDescription"
    :invalid-feedback-message="invalidFeedbackMessage"
    :is-loading="isLoading"
    :is-project="isProject"
    :new-users-to-invite="newUsersToInvite"
    :root-group-id="rootId"
    :users-limit-dataset="usersLimitDataset"
    :full-path="fullPath"
    @close="onClose"
    @cancel="onCancel"
    @reset="resetFields"
    @submit="sendInvite"
  >
    <template #intro-text-before>
      <div v-if="isCelebration" class="gl-p-4 gl-text-size-h1">
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
          <ul class="gl-mb-0 gl-pl-5">
            <li
              v-for="error in errorsLimited"
              :key="error.member"
              data-testid="errors-limited-item"
            >
              <strong>{{ error.displayedMemberName }}:</strong>
              <span v-safe-html="error.message"></span>
            </li>
          </ul>
          <template v-if="shouldErrorsSectionExpand">
            <gl-collapse v-model="isErrorsSectionExpanded">
              <ul class="gl-mb-0 gl-pl-5">
                <li
                  v-for="error in errorsExpanded"
                  :key="error.member"
                  data-testid="errors-expanded-item"
                >
                  <strong>{{ error.displayedMemberName }}:</strong>
                  <span v-safe-html="error.message"></span>
                </li>
              </ul>
            </gl-collapse>
            <gl-button
              class="gl-mt-3 !gl-no-underline !gl-shadow-none"
              data-testid="accordion-button"
              variant="link"
              @click="toggleErrorExpansion"
            >
              {{ errorCollapseText }}
              <gl-icon
                name="chevron-down"
                class="gl-transition-all"
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
        :users-with-warning="usersWithWarning"
        :invalid-members="invalidMembers"
        @clear="clearValidation"
        @token-remove="removeToken"
      />
    </template>

    <template #after-members-input>
      <gl-alert
        v-if="shouldShowSeatOverageNotification"
        id="seat-overages-alert"
        class="gl-mb-4"
        dismissable
        data-testid="seat-overages-alert"
        :primary-button-link="addSeatsHref"
        :primary-button-text="primaryButtonText"
        @dismiss="errorReason = false"
      >
        {{ $options.i18n.BLOCKED_SEAT_OVERAGES_BODY }}
      </gl-alert>
    </template>
  </invite-modal-base>
</template>
