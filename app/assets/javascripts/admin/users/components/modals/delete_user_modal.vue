<script>
import { GlModal, GlButton, GlFormInput, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';
import SoloOwnedOrganizationsMessage from '~/admin/users/components/solo_owned_organizations_message.vue';
import { SOLO_OWNED_ORGANIZATIONS_EMPTY } from '~/admin/users/constants';
import AssociationsList from '../associations/associations_list.vue';
import eventHub, { EVENT_OPEN_DELETE_USER_MODAL } from './delete_user_modal_event_hub';

export default {
  components: {
    GlModal,
    GlButton,
    GlFormInput,
    GlSprintf,
    UserDeletionObstaclesList,
    AssociationsList,
    SoloOwnedOrganizationsMessage,
  },
  props: {
    csrfToken: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      enteredUsername: '',
      username: '',
      blockPath: '',
      deletePath: '',
      userDeletionObstacles: [],
      associationsCount: {},
      organizations: SOLO_OWNED_ORGANIZATIONS_EMPTY,
      i18n: {
        title: '',
        primaryButtonLabel: '',
        messageBody: '',
      },
    };
  },
  computed: {
    trimmedUsername() {
      return this.username.trim();
    },
    modalTitle() {
      return sprintf(this.i18n.title, { username: this.trimmedUsername }, false);
    },
    canSubmit() {
      return this.enteredUsername && this.enteredUsername === this.trimmedUsername;
    },
    secondaryButtonLabel() {
      return s__('AdminUsers|Block user');
    },
    showSoloOwnedOrganizationsMessage() {
      return (this.organizations?.count || 0) > 0;
    },
  },
  mounted() {
    eventHub.$on(EVENT_OPEN_DELETE_USER_MODAL, this.onOpenEvent);
  },
  destroyed() {
    eventHub.$off(EVENT_OPEN_DELETE_USER_MODAL, this.onOpenEvent);
  },
  methods: {
    onOpenEvent({
      username,
      blockPath,
      deletePath,
      userDeletionObstacles,
      associationsCount = {},
      organizations = SOLO_OWNED_ORGANIZATIONS_EMPTY,
      i18n,
    }) {
      this.username = username;
      this.blockPath = blockPath;
      this.deletePath = deletePath;
      this.userDeletionObstacles = userDeletionObstacles;
      this.associationsCount = associationsCount;
      this.organizations = organizations;
      this.i18n = i18n;
      this.openModal();
    },
    openModal() {
      this.$refs.modal.show();
    },
    onSubmit() {
      this.$refs.form.submit();
      this.enteredUsername = '';
    },
    onCancel() {
      this.enteredUsername = '';
      this.$refs.modal.hide();
    },
    onSecondaryAction() {
      const { form } = this.$refs;
      form.action = this.blockPath;
      this.$refs.method.value = 'put';
      form.submit();
    },
  },
};
</script>
<template>
  <gl-modal ref="modal" modal-id="delete-user-modal" :title="modalTitle" kind="danger">
    <solo-owned-organizations-message
      v-if="showSoloOwnedOrganizationsMessage"
      :organizations="organizations"
    />
    <template v-else>
      <p>
        <gl-sprintf :message="i18n.messageBody">
          <template #username>
            <strong data-testid="message-username">{{ trimmedUsername }}</strong>
          </template>
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </p>

      <user-deletion-obstacles-list
        v-if="userDeletionObstacles.length"
        :obstacles="userDeletionObstacles"
        :user-name="trimmedUsername"
      />

      <associations-list :associations-count="associationsCount" />

      <p>
        <gl-sprintf :message="s__('AdminUsers|To confirm, type %{username}.')">
          <template #username>
            <code data-testid="confirm-username" class="gl-whitespace-pre-wrap">{{
              trimmedUsername
            }}</code>
          </template>
        </gl-sprintf>
      </p>

      <form ref="form" :action="deletePath" method="post" @submit.prevent>
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
        <gl-form-input
          v-model="enteredUsername"
          autofocus
          type="text"
          name="username"
          autocomplete="off"
        />
      </form>
    </template>
    <template #modal-footer>
      <gl-button data-testid="cancel-button" @click="onCancel">{{ __('Cancel') }}</gl-button>
      <template v-if="!showSoloOwnedOrganizationsMessage">
        <gl-button
          :disabled="!canSubmit"
          category="secondary"
          variant="danger"
          @click="onSecondaryAction"
        >
          {{ secondaryButtonLabel }}
        </gl-button>
        <gl-button :disabled="!canSubmit" category="primary" variant="danger" @click="onSubmit">{{
          i18n.primaryButtonLabel
        }}</gl-button>
      </template>
    </template>
  </gl-modal>
</template>
