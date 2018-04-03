<script>
import axios from 'axios';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import { s__, sprintf } from '~/locale';
import Flash from '~/flash';

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
    initialUsername: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      username: this.initialUsername,
      newUsername: this.initialUsername,
    };
  },
  computed: {
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
      const username = this.newUsername;
      const putData = {
        user: {
          username,
        },
      };

      axios
        .put(this.actionUrl, putData, { maxRedirects: 0 })
        .then(({ data }) => {
          Flash(data.message, 'notice');
          this.username = username;
        })
        .catch(error => {
          Flash(error.response.data.message);
        });
    },
  },
};
</script>
<template>
  <div>
    <div class="form-group">
      <label for="modal-username-change-input">Path</label>
      <div class="input-group">
        <div class="input-group-addon">{{ rootUrl }}</div>
        <input
          id="modal-username-change-input"
          class="form-control"
          required="required"
          v-model="newUsername"
        />
      </div>
      <p class="help-block">
        Current path: {{ rootUrl }}{{ username }}
      </p>
    </div>
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
