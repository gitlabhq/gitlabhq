<script>
import {
  GlFormGroup,
  GlModal,
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlLink,
  GlSprintf,
  GlButton,
  GlFormInput,
} from '@gitlab/ui';
import { partition, isString } from 'lodash';
import Api from '~/api';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { s__, sprintf } from '~/locale';
import { INVITE_MEMBERS_IN_COMMENT, GROUP_FILTERS } from '../constants';
import eventHub from '../event_hub';
import {
  responseMessageFromError,
  responseMessageFromSuccess,
} from '../utils/response_message_parser';
import GroupSelect from './group_select.vue';
import MembersTokenSelect from './members_token_select.vue';

export default {
  name: 'InviteMembersModal',
  components: {
    GlFormGroup,
    GlDatepicker,
    GlLink,
    GlModal,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlButton,
    GlFormInput,
    MembersTokenSelect,
    GroupSelect,
  },
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
    helpLink: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      visible: true,
      modalId: 'invite-members-modal',
      selectedAccessLevel: this.defaultAccessLevel,
      inviteeType: 'members',
      newUsersToInvite: [],
      selectedDate: undefined,
      groupToBeSharedWith: {},
      source: 'unknown',
      invalidFeedbackMessage: '',
    };
  },
  computed: {
    validationState() {
      return this.invalidFeedbackMessage === '' ? null : false;
    },
    isInviteGroup() {
      return this.inviteeType === 'group';
    },
    introText() {
      const inviteTo = this.isProject ? 'toProject' : 'toGroup';

      return sprintf(this.$options.labels[this.inviteeType][inviteTo].introText, {
        name: this.name,
      });
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
  },
  mounted() {
    eventHub.$on('openModal', (options) => {
      this.openModal(options);
    });
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
    openModal({ inviteeType, source }) {
      this.inviteeType = inviteeType;
      this.source = source;

      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    closeModal() {
      this.resetFields();
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    sendInvite() {
      if (this.isInviteGroup) {
        this.submitShareWithGroup();
      } else {
        this.submitInviteMembers();
      }
    },
    trackInvite() {
      if (this.source === INVITE_MEMBERS_IN_COMMENT) {
        const tracking = new ExperimentTracking(INVITE_MEMBERS_IN_COMMENT);
        tracking.event('comment_invite_success');
      }
    },
    resetFields() {
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;
      this.newUsersToInvite = [];
      this.groupToBeSharedWith = {};
      this.invalidFeedbackMessage = '';
    },
    changeSelectedItem(item) {
      this.selectedAccessLevel = item;
    },
    submitShareWithGroup() {
      const apiShareWithGroup = this.isProject
        ? Api.projectShareWithGroup.bind(Api)
        : Api.groupShareWithGroup.bind(Api);

      apiShareWithGroup(this.id, this.shareWithGroupPostData(this.groupToBeSharedWith.id))
        .then(this.showToastMessageSuccess)
        .catch(this.showInvalidFeedbackMessage);
    },
    submitInviteMembers() {
      this.invalidFeedbackMessage = '';

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
      this.trackInvite();

      Promise.all(promises)
        .then(this.conditionallyShowToastSuccess)
        .catch(this.showInvalidFeedbackMessage);
    },
    inviteByEmailPostData(usersToInviteByEmail) {
      return {
        ...this.basePostData,
        email: usersToInviteByEmail,
        access_level: this.selectedAccessLevel,
        invite_source: this.source,
      };
    },
    addByUserIdPostData(usersToAddById) {
      return {
        ...this.basePostData,
        user_id: usersToAddById,
        access_level: this.selectedAccessLevel,
        invite_source: this.source,
      };
    },
    shareWithGroupPostData(groupToBeSharedWith) {
      return {
        ...this.basePostData,
        group_id: groupToBeSharedWith,
        group_access: this.selectedAccessLevel,
      };
    },
    conditionallyShowToastSuccess(response) {
      const message = responseMessageFromSuccess(response);

      if (message === '') {
        this.showToastMessageSuccess();

        return;
      }

      this.invalidFeedbackMessage = message;
    },
    showToastMessageSuccess() {
      this.$toast.show(this.$options.labels.toastMessageSuccessful, this.toastOptions);
      this.closeModal();
    },
    showInvalidFeedbackMessage(response) {
      this.invalidFeedbackMessage =
        responseMessageFromError(response) || this.$options.labels.invalidFeedbackMessageDefault;
    },
    handleMembersTokenSelectClear() {
      this.invalidFeedbackMessage = '';
    },
  },
  labels: {
    members: {
      modalTitle: s__('InviteMembersModal|Invite members'),
      searchField: s__('InviteMembersModal|GitLab member or email address'),
      placeHolder: s__('InviteMembersModal|Select members or type email addresses'),
      toGroup: {
        introText: s__(
          "InviteMembersModal|You're inviting members to the %{strongStart}%{name}%{strongEnd} group.",
        ),
      },
      toProject: {
        introText: s__(
          "InviteMembersModal|You're inviting members to the %{strongStart}%{name}%{strongEnd} project.",
        ),
      },
    },
    group: {
      modalTitle: s__('InviteMembersModal|Invite a group'),
      searchField: s__('InviteMembersModal|Select a group to invite'),
      placeHolder: s__('InviteMembersModal|Search for a group to invite'),
      toGroup: {
        introText: s__(
          "InviteMembersModal|You're inviting a group to the %{strongStart}%{name}%{strongEnd} group.",
        ),
      },
      toProject: {
        introText: s__(
          "InviteMembersModal|You're inviting a group to the %{strongStart}%{name}%{strongEnd} project.",
        ),
      },
    },
    accessLevel: s__('InviteMembersModal|Select a role'),
    accessExpireDate: s__('InviteMembersModal|Access expiration date (optional)'),
    toastMessageSuccessful: s__('InviteMembersModal|Members were successfully added'),
    invalidFeedbackMessageDefault: s__('InviteMembersModal|Something went wrong'),
    readMoreText: s__(`InviteMembersModal|%{linkStart}Read more%{linkEnd} about role permissions`),
    inviteButtonText: s__('InviteMembersModal|Invite'),
    cancelButtonText: s__('InviteMembersModal|Cancel'),
    headerCloseLabel: s__('InviteMembersModal|Close invite team members'),
  },
  membersTokenSelectLabelId: 'invite-members-input',
};
</script>
<template>
  <gl-modal
    :modal-id="modalId"
    size="sm"
    data-qa-selector="invite_members_modal_content"
    :title="$options.labels[inviteeType].modalTitle"
    :header-close-label="$options.labels.headerCloseLabel"
    @close="resetFields"
  >
    <div>
      <p ref="introText">
        <gl-sprintf :message="introText">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </p>

      <gl-form-group
        class="gl-mt-2"
        :invalid-feedback="invalidFeedbackMessage"
        :state="validationState"
        :description="$options.labels[inviteeType].placeHolder"
        data-testid="members-form-group"
      >
        <label :id="$options.membersTokenSelectLabelId" class="col-form-label">{{
          $options.labels[inviteeType].searchField
        }}</label>
        <members-token-select
          v-if="!isInviteGroup"
          v-model="newUsersToInvite"
          :validation-state="validationState"
          :aria-labelledby="$options.membersTokenSelectLabelId"
          @clear="handleMembersTokenSelectClear"
        />
        <group-select
          v-if="isInviteGroup"
          v-model="groupToBeSharedWith"
          :groups-filter="groupSelectFilter"
          :parent-group-id="groupSelectParentId"
        />
      </gl-form-group>

      <label class="gl-font-weight-bold gl-mt-3">{{ $options.labels.accessLevel }}</label>
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

      <label class="gl-font-weight-bold gl-mt-5 gl-display-block" for="expires_at">{{
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
    </div>

    <template #modal-footer>
      <div class="gl-display-flex gl-flex-direction-row gl-justify-content-end gl-flex-wrap gl-m-0">
        <gl-button data-testid="cancel-button" @click="closeModal">
          {{ $options.labels.cancelButtonText }}
        </gl-button>
        <div class="gl-mr-3"></div>
        <gl-button
          :disabled="inviteDisabled"
          variant="success"
          data-qa-selector="invite_button"
          data-testid="invite-button"
          @click="sendInvite"
          >{{ $options.labels.inviteButtonText }}</gl-button
        >
      </div>
    </template>
  </gl-modal>
</template>
