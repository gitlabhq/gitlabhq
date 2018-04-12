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
      isRequestPending: false,
      username: this.initialUsername,
      newUsername: this.initialUsername,
    };
  },
  computed: {
    path() {
      return sprintf(s__('Profiles|Current path: %{path}'), {
        path: `${this.rootUrl}${this.username}`,
      });
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
      this.isRequestPending = true;
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
          this.isRequestPending = false;
        })
        .catch(error => {
          Flash(error.response.data.message);
          this.isRequestPending = false;
          throw error;
        });
    },
  },
  modalId: 'username-change-confirmation-modal',
  inputId: 'username-change-input',
  buttonText: s__('Profiles|Update username'),
};
</script>
<template>
  <div>
    <div class="form-group">
      <label :for="$options.inputId">{{ s__('Profiles|Path') }}</label>
      <div class="input-group">
        <div class="input-group-prepend">
          <div class="input-group-text">
            {{ rootUrl }}
          </div>
        </div>
        <input
          :id="$options.inputId"
          class="form-control"
          required="required"
          v-model="newUsername"
          :disabled="isRequestPending"
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
      :disabled="isRequestPending || newUsername === username"
    >
      {{ $options.buttonText }}
    </button>
    <gl-modal
      :id="$options.modalId"
      :header-title-text="s__('Profiles|Change username') + '?'"
      footer-primary-button-variant="warning"
      :footer-primary-button-text="$options.buttonText"
      @submit="onConfirm"
    >
      <span v-html="modalText"></span>
    </gl-modal>
  </div>
</template>
