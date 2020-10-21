<script>
import {
  GlModal,
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlLink,
  GlSprintf,
  GlSearchBoxByType,
  GlButton,
  GlFormInput,
} from '@gitlab/ui';
import eventHub from '../event_hub';
import { s__, sprintf } from '~/locale';
import Api from '~/api';

export default {
  name: 'InviteMembersModal',
  components: {
    GlDatepicker,
    GlLink,
    GlModal,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlSearchBoxByType,
    GlButton,
    GlFormInput,
  },
  props: {
    groupId: {
      type: String,
      required: true,
    },
    groupName: {
      type: String,
      required: true,
    },
    accessLevels: {
      type: Object,
      required: true,
    },
    defaultAccessLevel: {
      type: String,
      required: true,
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
      newUsersToInvite: '',
      selectedDate: undefined,
    };
  },
  computed: {
    introText() {
      return sprintf(s__("InviteMembersModal|You're inviting members to the %{group_name} group"), {
        group_name: this.groupName,
      });
    },
    toastOptions() {
      return {
        onComplete: () => {
          this.selectedAccessLevel = this.defaultAccessLevel;
          this.newUsersToInvite = '';
        },
      };
    },
    postData() {
      return {
        user_id: this.newUsersToInvite,
        access_level: this.selectedAccessLevel,
        expires_at: this.selectedDate,
        format: 'json',
      };
    },
    selectedRoleName() {
      return Object.keys(this.accessLevels).find(
        key => this.accessLevels[key] === Number(this.selectedAccessLevel),
      );
    },
  },
  mounted() {
    eventHub.$on('openModal', this.openModal);
  },
  methods: {
    openModal() {
      this.$root.$emit('bv::show::modal', this.modalId);
    },
    closeModal() {
      this.$root.$emit('bv::hide::modal', this.modalId);
    },
    sendInvite() {
      this.submitForm(this.postData);
      this.closeModal();
    },
    cancelInvite() {
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;
      this.newUsersToInvite = '';
      this.closeModal();
    },
    changeSelectedItem(item) {
      this.selectedAccessLevel = item;
    },
    submitForm(formData) {
      return Api.inviteGroupMember(this.groupId, formData)
        .then(() => {
          this.showToastMessageSuccess();
        })
        .catch(error => {
          this.showToastMessageError(error);
        });
    },
    showToastMessageSuccess() {
      this.$toast.show(this.$options.labels.toastMessageSuccessful, this.toastOptions);
    },
    showToastMessageError(error) {
      const message = error.response.data.message || this.$options.labels.toastMessageUnsuccessful;

      this.$toast.show(message, this.toastOptions);
    },
  },
  labels: {
    modalTitle: s__('InviteMembersModal|Invite team members'),
    userToInvite: s__('InviteMembersModal|GitLab member or Email address'),
    userPlaceholder: s__('InviteMembersModal|Search for members to invite'),
    accessLevel: s__('InviteMembersModal|Choose a role permission'),
    accessExpireDate: s__('InviteMembersModal|Access expiration date (optional)'),
    toastMessageSuccessful: s__('InviteMembersModal|Users were succesfully added'),
    toastMessageUnsuccessful: s__('InviteMembersModal|User not invited. Feature coming soon!'),
    readMoreText: s__(`InviteMembersModal|%{linkStart}Read more%{linkEnd} about role permissions`),
    inviteButtonText: s__('InviteMembersModal|Invite'),
    cancelButtonText: s__('InviteMembersModal|Cancel'),
  },
};
</script>
<template>
  <gl-modal :modal-id="modalId" size="sm" :title="$options.labels.modalTitle">
    <div class="gl-ml-5 gl-mr-5">
      <div>{{ introText }}</div>

      <label class="gl-font-weight-bold gl-mt-5">{{ $options.labels.userToInvite }}</label>
      <div class="gl-mt-2">
        <gl-search-box-by-type
          v-model="newUsersToInvite"
          :placeholder="$options.labels.userPlaceholder"
          type="text"
          autocomplete="off"
          autocorrect="off"
          autocapitalize="off"
          spellcheck="false"
        />
      </div>

      <label class="gl-font-weight-bold gl-mt-5">{{ $options.labels.accessLevel }}</label>
      <div class="gl-mt-2 gl-w-half gl-xs-w-full">
        <gl-dropdown
          menu-class="dropdown-menu-selectable"
          class="gl-shadow-none gl-w-full"
          v-bind="$attrs"
          :text="selectedRoleName"
        >
          <template v-for="(key, item) in accessLevels">
            <gl-dropdown-item
              :key="key"
              active-class="is-active"
              :is-checked="key === selectedAccessLevel"
              @click="changeSelectedItem(key)"
            >
              <div>{{ item }}</div>
            </gl-dropdown-item>
          </template>
        </gl-dropdown>
      </div>

      <div class="gl-mt-2">
        <gl-sprintf :message="$options.labels.readMoreText">
          <template #link="{content}">
            <gl-link :href="helpLink" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>

      <label class="gl-font-weight-bold gl-mt-5" for="expires_at">{{
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
      <div class="gl-display-flex gl-flex-direction-row gl-justify-content-end gl-flex-wrap gl-p-3">
        <gl-button ref="cancelButton" @click="cancelInvite">
          {{ $options.labels.cancelButtonText }}
        </gl-button>
        <div class="gl-mr-3"></div>
        <gl-button ref="inviteButton" variant="success" @click="sendInvite">{{
          $options.labels.inviteButtonText
        }}</gl-button>
      </div>
    </template>
  </gl-modal>
</template>
