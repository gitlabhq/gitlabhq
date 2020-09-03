<script>
/* eslint-disable vue/no-v-html */
import { GlModal } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
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
    confirmWithPassword: {
      type: Boolean,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      enteredPassword: '',
      enteredUsername: '',
    };
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
    inputLabel() {
      let confirmationValue;
      if (this.confirmWithPassword) {
        confirmationValue = __('password');
      } else {
        confirmationValue = __('username');
      }

      confirmationValue = `<code>${confirmationValue}</code>`;

      return sprintf(
        s__('Profiles|Type your %{confirmationValue} to confirm:'),
        { confirmationValue },
        false,
      );
    },
    text() {
      return sprintf(
        s__(`Profiles|
You are about to permanently delete %{yourAccount}, and all of the issues, merge requests, and groups linked to your account.
Once you confirm %{deleteAccount}, it cannot be undone or recovered.`),
        {
          yourAccount: `<strong>${s__('Profiles|your account')}</strong>`,
          deleteAccount: `<strong>${s__('Profiles|Delete account')}</strong>`,
        },
        false,
      );
    },
    primaryProps() {
      return {
        text: s__('Delete account'),
        attributes: [
          { variant: 'danger', 'data-qa-selector': 'confirm_delete_account_button' },
          { category: 'primary' },
          { disabled: !this.canSubmit },
        ],
      };
    },
    cancelProps() {
      return {
        text: s__('Cancel'),
      };
    },
    canSubmit() {
      if (this.confirmWithPassword) {
        return this.enteredPassword !== '';
      }
      return this.enteredUsername === this.username;
    },
  },
  methods: {
    onSubmit() {
      if (!this.canSubmit) {
        return;
      }
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="delete-account-modal"
    title="Profiles"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    :ok-disabled="!canSubmit"
    @primary="onSubmit"
  >
    <p v-html="text"></p>

    <form ref="form" :action="actionUrl" method="post">
      <input type="hidden" name="_method" value="delete" />
      <input :value="csrfToken" type="hidden" name="authenticity_token" />

      <p id="input-label" v-html="inputLabel"></p>

      <input
        v-if="confirmWithPassword"
        v-model="enteredPassword"
        name="password"
        class="form-control"
        type="password"
        data-qa-selector="password_confirmation_field"
        aria-labelledby="input-label"
      />
      <input
        v-else
        v-model="enteredUsername"
        name="username"
        class="form-control"
        type="text"
        aria-labelledby="input-label"
      />
    </form>
  </gl-modal>
</template>
