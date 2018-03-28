<script>
import GlModal from '~/vue_shared/components/gl_modal.vue';
import { s__, sprintf } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
  },
  props: {
    actionUrl: {
      type: String,
      required: true,
    },
    rootUrl: {
      type: String,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      newUsername: this.username,
    };
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
    buttonText() {
      return s__('Profiles|Update username');
    },
    modalText() {
      return sprintf(
        s__(`Profiles|
You are going to change the username %{currentUsernameBold} to %{newUsernameBold}.
Profile and projects will be redirected to the %{newUsername} namespace but this redirect will expire once the %{currentUsername} namespace is registered by another user or group.
Please update your Git repository remotes as soon as possible.`),
        {
          currentUsernameBold: `<strong>${this.username}</strong>`,
          newUsernameBold: `<strong>${this.newUsername}</strong>`,
          currentUsername: this.username,
          newUsername: this.newUsername,
        },
        false,
      );
    },
  },
  methods: {
    onConfirm() {
      this.$refs.form.submit();
    },
  },
};
</script>
<template>
  <div>
    <form
      ref="form"
      :action="actionUrl"
      method="post">
      <input
        type="hidden"
        name="_method"
        value="put"
      />
      <input
        type="hidden"
        name="authenticity_token"
        :value="csrfToken"
      />
      <div class="form-group">
        <label>Path</label>
        <div class="input-group">
          <div class="input-group-addon">{{ rootUrl }}</div>
          <input
            name="user[username]"
            class="form-control"
            required="required"
            v-model="newUsername"
          />
        </div>
        <p class="help-block">
          Current path: {{ rootUrl }}{{ username }}
        </p>
      </div>
    </form>
    <button
      data-target="#modal-username-change-confirmation"
      class="btn btn-warning"
      type="button"
      data-toggle="modal"
      :disabled="newUsername === username"
    >
      {{ buttonText }}
    </button>
    <gl-modal
      id="modal-username-change-confirmation"
      class="performance-bar-modal"
      header-title-text="Change username?"
      footer-primary-button-variant="warning"
      :footer-primary-button-text="buttonText"
      @submit="onConfirm"
    >
      <span v-html="modalText"></span>
    </gl-modal>
  </div>
</template>
