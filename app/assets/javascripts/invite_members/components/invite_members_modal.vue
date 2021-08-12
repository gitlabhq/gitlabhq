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
  GlFormCheckboxGroup,
} from '@gitlab/ui';
import { partition, isString } from 'lodash';
import Api from '~/api';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { s__, sprintf } from '~/locale';
import {
  INVITE_MEMBERS_IN_COMMENT,
  GROUP_FILTERS,
  USERS_FILTER_ALL,
  MEMBER_AREAS_OF_FOCUS,
} from '../constants';
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
    GlFormCheckboxGroup,
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
    areasOfFocusOptions: {
      type: Array,
      required: true,
    },
    noSelectionAreasOfFocus: {
      type: Array,
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
      selectedAreasOfFocus: [],
      groupToBeSharedWith: {},
      source: 'unknown',
      invalidFeedbackMessage: '',
      isLoading: false,
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
    areasOfFocusEnabled() {
      return this.areasOfFocusOptions.length !== 0;
    },
    areasOfFocusForPost() {
      if (this.selectedAreasOfFocus.length === 0 && this.areasOfFocusEnabled) {
        return this.noSelectionAreasOfFocus;
      }

      return this.selectedAreasOfFocus;
    },
    errorFieldDescription() {
      if (this.inviteeType === 'group') {
        return '';
      }

      return this.$options.labels[this.inviteeType].placeHolder;
    },
  },
  mounted() {
    eventHub.$on('openModal', (options) => {
      this.openModal(options);
      this.trackEvent(MEMBER_AREAS_OF_FOCUS.name, MEMBER_AREAS_OF_FOCUS.view);
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
    trackInvite() {
      if (this.source === INVITE_MEMBERS_IN_COMMENT) {
        this.trackEvent(INVITE_MEMBERS_IN_COMMENT, 'comment_invite_success');
      }

      this.trackEvent(MEMBER_AREAS_OF_FOCUS.name, MEMBER_AREAS_OF_FOCUS.submit);
    },
    resetFields() {
      this.isLoading = false;
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;
      this.newUsersToInvite = [];
      this.groupToBeSharedWith = {};
      this.invalidFeedbackMessage = '';
      this.selectedAreasOfFocus = [];
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
        areas_of_focus: this.areasOfFocusForPost,
      };
    },
    addByUserIdPostData(usersToAddById) {
      return {
        ...this.basePostData,
        user_id: usersToAddById,
        access_level: this.selectedAccessLevel,
        invite_source: this.source,
        areas_of_focus: this.areasOfFocusForPost,
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
      this.isLoading = false;
    },
    showToastMessageSuccess() {
      this.$toast.show(this.$options.labels.toastMessageSuccessful, this.toastOptions);
      this.closeModal();
    },
    showInvalidFeedbackMessage(response) {
      this.isLoading = false;
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
    areasOfFocusLabel: s__(
      'InviteMembersModal|What would you like new member(s) to focus on? (optional)',
    ),
  },
  membersTokenSelectLabelId: 'invite-members-input',
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    size="sm"
    data-qa-selector="invite_members_modal_content"
    :title="$options.labels[inviteeType].modalTitle"
    :header-close-label="$options.labels.headerCloseLabel"
    @hidden="resetFields"
    @close="resetFields"
    @hide="resetFields"
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
          :groups-filter="groupSelectFilter"
          :parent-group-id="groupSelectParentId"
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
      <div v-if="areasOfFocusEnabled">
        <label class="gl-mt-5">
          {{ $options.labels.areasOfFocusLabel }}
        </label>
        <gl-form-checkbox-group
          v-model="selectedAreasOfFocus"
          :options="areasOfFocusOptions"
          data-testid="area-of-focus-checks"
        />
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
          :loading="isLoading"
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
