<script>
import { GlFormGroup, GlModal, GlSprintf, GlAlert, GlCollapse, GlIcon, GlButton } from '@gitlab/ui';
import { uniqueId, isEmpty } from 'lodash';
import { importProjectMembers } from '~/api/projects_api';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { s__, __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import eventHub from '../event_hub';

import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '../utils/trigger_successful_invite_alert';

import {
  BLOCKED_SEAT_OVERAGES_ERROR_REASON,
  BLOCKED_SEAT_OVERAGES_BODY,
  BLOCKED_SEAT_OVERAGES_CTA,
  PROJECT_SELECT_LABEL_ID,
  IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_CATEGORY,
  IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_LABEL,
  MEMBER_MODAL_LABELS,
} from '../constants';

import { responseFromSuccess } from '../utils/response_message_parser';
import UserLimitNotification from './user_limit_notification.vue';
import ProjectSelect from './project_select.vue';

export default {
  name: 'ImportProjectMembersModal',
  components: {
    GlFormGroup,
    GlModal,
    GlSprintf,
    GlAlert,
    GlCollapse,
    GlIcon,
    GlButton,
    UserLimitNotification,
    ProjectSelect,
  },
  mixins: [
    Tracking.mixin({
      category: IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_CATEGORY,
      label: IMPORT_PROJECT_MEMBERS_MODAL_TRACKING_LABEL,
    }),
  ],
  inject: {
    addSeatsHref: {
      default: '',
    },
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
    reloadPageOnSubmit: {
      type: Boolean,
      required: false,
      default: false,
    },
    usersLimitDataset: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      errorReason: '',
      projectToBeImported: {},
      invalidFeedbackMessage: '',
      totalMembersCount: 0,
      invalidMembers: {},
      isErrorsSectionExpanded: false,
      isLoading: false,
    };
  },
  computed: {
    modalIntro() {
      return sprintf(this.$options.i18n.modalIntro, {
        name: this.projectName,
      });
    },
    importDisabled() {
      return Object.keys(this.projectToBeImported).length === 0;
    },
    validationState() {
      return this.invalidFeedbackMessage === '' ? null : false;
    },
    showUserLimitNotification() {
      return !isEmpty(this.usersLimitDataset.alertVariant);
    },
    limitVariant() {
      return this.usersLimitDataset.alertVariant;
    },
    actionPrimary() {
      return {
        text: this.$options.i18n.modalPrimaryButton,
        attributes: {
          variant: 'confirm',
          disabled: this.importDisabled,
          loading: this.isLoading,
        },
      };
    },
    actionCancel() {
      return { text: this.$options.i18n.modalCancelButton };
    },
    hasInvalidMembers() {
      return !isEmpty(this.invalidMembers);
    },
    memberErrorTitle() {
      return sprintf(
        s__(
          'InviteMembersModal|The following %{errorMembersLength} out of %{totalMembersCount} members could not be added',
        ),
        { errorMembersLength: this.errorList.length, totalMembersCount: this.totalMembersCount },
      );
    },
    errorList() {
      return Object.entries(this.invalidMembers).map(([member, error]) => {
        return { member, displayedMemberName: `@${member}`, message: error };
      });
    },
    errorsLimited() {
      return this.errorList.slice(0, this.$options.errorsLimit);
    },
    errorsExpanded() {
      return this.errorList.slice(this.$options.errorsLimit);
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
    shouldShowSeatOverageNotification() {
      return this.errorReason === BLOCKED_SEAT_OVERAGES_ERROR_REASON && this.addSeatsHref;
    },
  },
  mounted() {
    if (this.reloadPageOnSubmit) {
      displaySuccessfulInvitationAlert();
    }

    eventHub.$on('openProjectMembersModal', () => {
      this.openModal();
    });
  },
  methods: {
    openModal() {
      this.track('render');
      this.$root.$emit(BV_SHOW_MODAL, this.$options.modalId);
    },
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.$options.modalId);
    },
    resetFields() {
      this.clearValidation();
      this.invalidFeedbackMessage = '';
      this.projectToBeImported = {};
    },
    async submitImport(event) {
      // We never want to hide when submitting
      event.preventDefault();

      this.isLoading = true;

      try {
        const response = await importProjectMembers(this.projectId, this.projectToBeImported.id);

        const { error, message } = responseFromSuccess(response);

        if (error) {
          this.totalMembersCount = response.data.total_members_count;
          this.showMemberErrors(message);
        } else {
          this.onInviteSuccess();
        }
      } catch (error) {
        const { message, reason } = error.response.data || {};

        this.errorReason = reason;
        this.showErrorAlert(message);
      } finally {
        this.isLoading = false;
        this.projectToBeImported = {};
      }
    },
    showMemberErrors(message) {
      this.invalidMembers = message;
      this.$refs.alerts.focus();
    },
    onInviteSuccess() {
      this.track('invite_successful');

      if (this.reloadPageOnSubmit) {
        reloadOnInvitationSuccess();
      } else {
        this.showToastMessage();
      }
    },
    showToastMessage() {
      this.$toast.show(this.$options.i18n.successMessage, this.$options.toastOptions);
      this.closeModal();
    },
    showErrorAlert(message) {
      this.invalidFeedbackMessage = message || this.$options.i18n.defaultError;
    },
    onCancel() {
      this.track('click_cancel');
    },
    onClose() {
      this.track('click_x');
    },
    clearValidation() {
      this.errorReason = '';
      this.invalidFeedbackMessage = '';
      this.invalidMembers = {};
    },
    toggleErrorExpansion() {
      this.isErrorsSectionExpanded = !this.isErrorsSectionExpanded;
    },
  },
  toastOptions() {
    return {
      onComplete: () => {
        this.projectToBeImported = {};
      },
    };
  },
  i18n: {
    projectLabel: __('Project'),
    modalTitle: s__('ImportAProjectModal|Import members from another project'),
    modalIntro: s__(
      "ImportAProjectModal|You're importing members to the %{strongStart}%{name}%{strongEnd} project.",
    ),
    modalHelpText: s__(
      'ImportAProjectModal|Only project members (not group members) are imported, and they get the same permissions as the project you import from.',
    ),
    modalPrimaryButton: s__('ImportAProjectModal|Import project members'),
    modalCancelButton: __('Cancel'),
    defaultError: s__('ImportAProjectModal|Unable to import project members'),
    successMessage: s__('ImportAProjectModal|Successfully imported'),
    BLOCKED_SEAT_OVERAGES_BODY,
    BLOCKED_SEAT_OVERAGES_CTA,
  },
  errorsLimit: 2,
  projectSelectLabelId: PROJECT_SELECT_LABEL_ID,
  modalId: uniqueId('import-a-project-modal-'),
  labels: MEMBER_MODAL_LABELS,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    size="sm"
    :title="$options.i18n.modalTitle"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    data-testid="import-project-members-modal"
    no-focus-on-show
    @primary="submitImport"
    @hidden="resetFields"
    @cancel="onCancel"
    @close="onClose"
  >
    <div ref="alerts" tabindex="-1">
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
          <li v-for="error in errorsLimited" :key="error.member" data-testid="errors-limited-item">
            <strong>{{ error.displayedMemberName }}:</strong> {{ error.message }}
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
                <strong>{{ error.displayedMemberName }}:</strong> {{ error.message }}
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
    <p ref="modalIntro">
      <gl-sprintf :message="modalIntro">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group
      :invalid-feedback="invalidFeedbackMessage"
      :state="validationState"
      data-testid="form-group"
      label-class="!gl-pt-3"
      :label="$options.i18n.projectLabel"
      :label-for="$options.projectSelectLabelId"
    >
      <project-select v-model="projectToBeImported" />
    </gl-form-group>
    <gl-alert
      v-if="shouldShowSeatOverageNotification"
      id="import-project-members-seat-overages-alert"
      class="gl-mb-4"
      dismissable
      data-testid="import-project-members-seat-overages-alert"
      :primary-button-link="addSeatsHref"
      :primary-button-text="$options.i18n.BLOCKED_SEAT_OVERAGES_CTA"
      @dismiss="errorReason = false"
    >
      {{ $options.i18n.BLOCKED_SEAT_OVERAGES_BODY }}
    </gl-alert>
    <p>{{ $options.i18n.modalHelpText }}</p>
  </gl-modal>
</template>
