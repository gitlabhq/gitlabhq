<script>
import { uniqueId } from 'lodash';
import Api from '~/api';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { GROUP_FILTERS, GROUP_MODAL_LABELS } from '../constants';
import eventHub from '../event_hub';
import GroupSelect from './group_select.vue';
import InviteModalBase from './invite_modal_base.vue';

export default {
  name: 'InviteMembersModal',
  components: {
    GroupSelect,
    InviteModalBase,
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
  },
  data() {
    return {
      modalId: uniqueId('invite-groups-modal-'),
      groupToBeSharedWith: {},
    };
  },
  computed: {
    labelIntroText() {
      return this.$options.labels[this.inviteTo].introText;
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
  },
  mounted() {
    eventHub.$on('openGroupModal', () => {
      this.openModal();
    });
  },
  methods: {
    openModal() {
      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    sendInvite({ onError, onSuccess, data: { accessLevel, expiresAt } }) {
      const apiShareWithGroup = this.isProject
        ? Api.projectShareWithGroup.bind(Api)
        : Api.groupShareWithGroup.bind(Api);

      apiShareWithGroup(this.id, {
        format: 'json',
        group_id: this.groupToBeSharedWith.id,
        group_access: accessLevel,
        expires_at: expiresAt,
      })
        .then(() => {
          onSuccess();
          this.showSuccessMessage();
        })
        .catch(onError);
    },
    resetFields() {
      this.groupToBeSharedWith = {};
    },
    showSuccessMessage() {
      this.$toast.show(this.$options.labels.toastMessageSuccessful, this.toastOptions);
      this.closeModal();
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
    :access-levels="accessLevels"
    :default-access-level="defaultAccessLevel"
    :help-link="helpLink"
    v-bind="$attrs"
    :label-intro-text="labelIntroText"
    :label-search-field="$options.labels.searchField"
    :submit-disabled="inviteDisabled"
    @reset="resetFields"
    @submit="sendInvite"
  >
    <template #select="{ clearValidation }">
      <group-select
        v-model="groupToBeSharedWith"
        :access-levels="accessLevels"
        :groups-filter="groupSelectFilter"
        :parent-group-id="groupSelectParentId"
        :invalid-groups="invalidGroups"
        @input="clearValidation"
      />
    </template>
  </invite-modal-base>
</template>
