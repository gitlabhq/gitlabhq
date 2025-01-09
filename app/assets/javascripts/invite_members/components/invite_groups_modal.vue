<script>
import { GlAlert } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Api from '~/api';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import InviteModalBase from 'ee_else_ce/invite_members/components/invite_modal_base.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { GROUP_FILTERS, GROUP_MODAL_LABELS } from '../constants';
import eventHub from '../event_hub';
import { getInvalidFeedbackMessage } from '../utils/get_invalid_feedback_message';
import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '../utils/trigger_successful_invite_alert';
import GroupSelect from './group_select.vue';
import InviteGroupNotification from './invite_group_notification.vue';

export default {
  name: 'InviteGroupsModal',
  components: {
    GroupSelect,
    InviteModalBase,
    InviteGroupNotification,
    GlAlert,
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
    fullPath: {
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
    invalidGroups: {
      type: Array,
      required: true,
    },
    freeUserCapEnabled: {
      type: Boolean,
      required: true,
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
      modalId: uniqueId('invite-groups-modal-'),
      groupToBeSharedWith: {},
      groupSelectError: '',
    };
  },
  computed: {
    labelIntroText() {
      return this.$options.labels[this.inviteTo].introText;
    },
    accessExpirationHelpLink() {
      return this.isProject
        ? helpPagePath('user/project/members/sharing_projects_groups', {
            anchor: 'invite-a-group-to-a-project',
          })
        : helpPagePath('user/project/members/sharing_projects_groups', {
            anchor: 'invite-a-group-to-a-group',
          });
    },
    inviteTo() {
      return this.isProject ? 'toProject' : 'toGroup';
    },
    toastOptions() {
      return {
        onComplete: () => {
          this.groupToBeSharedWith = {};
        },
      };
    },
    inviteDisabled() {
      return Object.keys(this.groupToBeSharedWith).length === 0;
    },
    staticRoles() {
      return { validRoles: this.accessLevels };
    },
  },
  mounted() {
    if (this.reloadPageOnSubmit) {
      displaySuccessfulInvitationAlert();
    }

    eventHub.$on('openGroupModal', () => {
      this.openModal();
    });
  },
  methods: {
    showInvalidFeedbackMessage(response) {
      this.invalidFeedbackMessage = getInvalidFeedbackMessage(response);
    },
    openModal() {
      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    sendInvite({ accessLevel, expiresAt, memberRoleId }) {
      this.invalidFeedbackMessage = '';
      this.isLoading = true;

      const apiShareWithGroup = this.isProject
        ? Api.projectShareWithGroup.bind(Api)
        : Api.groupShareWithGroup.bind(Api);

      apiShareWithGroup(this.id, {
        format: 'json',
        group_id: this.groupToBeSharedWith.id,
        group_access: accessLevel,
        expires_at: expiresAt,
        member_role_id: memberRoleId,
      })
        .then(() => {
          this.onInviteSuccess();
        })
        .catch((e) => {
          this.showInvalidFeedbackMessage(e);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    resetFields() {
      this.invalidFeedbackMessage = '';
      this.isLoading = false;
      this.groupToBeSharedWith = {};
    },
    onInviteSuccess() {
      if (this.reloadPageOnSubmit) {
        reloadOnInvitationSuccess();
      } else {
        this.showSuccessMessage();
      }
    },
    showSuccessMessage() {
      this.$toast.show(this.$options.labels.toastMessageSuccessful, this.toastOptions);
      this.closeModal();
    },
    clearValidation() {
      this.invalidFeedbackMessage = '';
    },
    onGroupSelectError(error) {
      this.groupSelectError = error;
      Sentry.captureException(error);
    },
  },
  labels: GROUP_MODAL_LABELS,
};
</script>
<template>
  <invite-modal-base
    :modal-id="modalId"
    :modal-title="$options.labels.title"
    :name="name"
    :access-levels="staticRoles"
    :default-access-level="defaultAccessLevel"
    :help-link="helpLink"
    :access-expiration-help-link="accessExpirationHelpLink"
    v-bind="$attrs"
    :label-intro-text="labelIntroText"
    :label-search-field="$options.labels.searchField"
    :submit-disabled="inviteDisabled"
    :new-group-to-invite="groupToBeSharedWith.id"
    :root-group-id="rootId"
    :invalid-feedback-message="invalidFeedbackMessage"
    :is-loading="isLoading"
    :full-path="fullPath"
    :is-project="isProject"
    is-group-invite
    @reset="resetFields"
    @submit="sendInvite"
  >
    <template #alert>
      <invite-group-notification
        v-if="freeUserCapEnabled"
        :name="name"
        :notification-text="$options.labels[inviteTo].notificationText"
        :notification-link="$options.labels[inviteTo].notificationLink"
        class="gl-mb-5"
      />
      <gl-alert v-if="groupSelectError" class="gl-mb-5" variant="danger" :dismissible="false">{{
        groupSelectError
      }}</gl-alert>
    </template>

    <template #select>
      <group-select
        v-model="groupToBeSharedWith"
        :source-id="id"
        :groups-filter="groupSelectFilter"
        :parent-group-id="groupSelectParentId"
        :invalid-groups="invalidGroups"
        :is-project="isProject"
        @input="clearValidation"
        @error="onGroupSelectError"
      />
    </template>
  </invite-modal-base>
</template>
