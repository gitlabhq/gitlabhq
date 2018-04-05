<script>
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
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
      inputDisabled: false,
      username: this.initialUsername,
      newUsername: this.initialUsername,
    };
  },
  computed: {
    path() {
      return sprintf(s__('Profiles|Current path: %{path}'), {
        path: _.escape(`${this.rootUrl}${this.username}`),
      });
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
          currentUsernameBold: `<strong>${_.escape(this.username)}</strong>`,
          newUsernameBold: `<strong>${_.escape(this.newUsername)}</strong>`,
          currentUsername: _.escape(this.username),
          newUsername: _.escape(this.newUsername),
        },
        false,
      );
    },
  },
  methods: {
    onConfirm() {
      this.inputDisabled = true;
      const username = this.newUsername;
      const putData = {
        user: {
          username,
        },
      };

      return axios
        .put(this.actionUrl, putData)
        .then(result => {
          Flash(result.data.message, 'notice');
          this.username = username;
          this.newUsername = username;
          this.inputDisabled = false;
        })
        .catch(error => {
          Flash(error.response.data.message);
          this.inputDisabled = false;
          throw error;
        });
    },
  },
  modalId: 'username-change-confirmation-modal',
  inputId: 'username-change-input',
};
</script>
<template>
  <div>
    <div class="form-group">
      <label :for="$options.inputId">{{ s__('Profiles|Path') }}</label>
      <div class="input-group">
        <div class="input-group-addon">{{ rootUrl }}</div>
        <input
          :id="$options.inputId"
          class="form-control"
          required="required"
          v-model="newUsername"
          :disabled="inputDisabled"
        />
      </div>
      <p class="help-block">
        {{ path }}
      </p>
    </div>
    <button
      :data-target="`#${$options.modalId}`"
      class="btn btn-warning"
      type="button"
      data-toggle="modal"
      :disabled="inputDisabled || newUsername === username"
    >
      {{ buttonText }}
    </button>
    <gl-modal
      :id="$options.modalId"
      :header-title-text="s__('Profiles|Change username') + '?'"
      footer-primary-button-variant="warning"
      :footer-primary-button-text="buttonText"
      @submit="onConfirm"
    >
      <span v-html="modalText"></span>
    </gl-modal>
  </div>
</template>
