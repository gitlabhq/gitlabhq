<script>
import { GlModal, GlButton, GlFormInput, GlSprintf } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__, sprintf } from '~/locale';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';

export default {
  components: {
    GlModal,
    GlButton,
    GlFormInput,
    GlSprintf,
    UserDeletionObstaclesList,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
    },
    secondaryAction: {
      type: String,
      required: true,
    },
    deleteUserUrl: {
      type: String,
      required: true,
    },
    blockUserUrl: {
      type: String,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
    userDeletionObstacles: {
      type: String,
      required: false,
      default: '[]',
    },
  },
  data() {
    return {
      enteredUsername: '',
    };
  },
  computed: {
    modalTitle() {
      return sprintf(this.title, { username: this.username }, false);
    },
    secondaryButtonLabel() {
      return s__('AdminUsers|Block user');
    },
    canSubmit() {
      return this.enteredUsername === this.username;
    },
    obstacles() {
      try {
        return JSON.parse(this.userDeletionObstacles);
      } catch (e) {
        Sentry.captureException(e);
      }
      return [];
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    onCancel() {
      this.enteredUsername = '';
      this.$refs.modal.hide();
    },
    onSecondaryAction() {
      const { form } = this.$refs;

      form.action = this.blockUserUrl;
      this.$refs.method.value = 'put';

      form.submit();
    },
    onSubmit() {
      this.$refs.form.submit();
      this.enteredUsername = '';
    },
  },
};
</script>

<template>
  <gl-modal ref="modal" modal-id="delete-user-modal" :title="modalTitle" kind="danger">
    <p>
      <gl-sprintf :message="content">
        <template #username>
          <strong>{{ username }}</strong>
        </template>
        <template #strong="props">
          <strong>{{ props.content }}</strong>
        </template>
      </gl-sprintf>
    </p>

    <user-deletion-obstacles-list
      v-if="obstacles.length"
      :obstacles="obstacles"
      :user-name="username"
    />

    <p>
      <gl-sprintf :message="s__('AdminUsers|To confirm, type %{username}')">
        <template #username>
          <code class="gl-white-space-pre-wrap">{{ username }}</code>
        </template>
      </gl-sprintf>
    </p>

    <form ref="form" :action="deleteUserUrl" method="post" @submit.prevent>
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
    <template #modal-footer>
      <gl-button @click="onCancel">{{ __('Cancel') }}</gl-button>
      <gl-button
        :disabled="!canSubmit"
        category="secondary"
        variant="danger"
        @click="onSecondaryAction"
      >
        {{ secondaryAction }}
      </gl-button>
      <gl-button :disabled="!canSubmit" category="primary" variant="danger" @click="onSubmit">{{
        action
      }}</gl-button>
    </template>
  </gl-modal>
</template>
