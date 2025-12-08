<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlModal,
    GlSprintf,
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
    delayUserAccountSelfDeletion: {
      type: Boolean,
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
    confirmationValue() {
      return this.confirmWithPassword ? __('password') : __('username');
    },
    primaryProps() {
      return {
        text: __('Delete account'),
        attributes: {
          variant: 'danger',
          'data-testid': 'confirm-delete-account-button',
          category: 'primary',
          disabled: !this.canSubmit,
        },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    canSubmit() {
      if (this.confirmWithPassword) {
        return this.enteredPassword !== '';
      }
      return this.enteredUsername === this.username;
    },
    deleteMessage() {
      return this.delayUserAccountSelfDeletion
        ? this.$options.i18n.textdelay
        : this.$options.i18n.text;
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
  i18n: {
    textdelay: s__(`Profiles|
You are about to permanently delete %{yourAccount}, and all of the issues, merge requests, and groups linked to your account.
Once you confirm %{deleteAccount}, your account cannot be recovered. It might take up to seven days before you can create a new account with the same username or email.`),
    text: s__(`Profiles|
You are about to permanently delete %{yourAccount}, and all of the issues, merge requests, and groups linked to your account.
Once you confirm %{deleteAccount}, your account cannot be recovered.`),
    inputLabel: s__('Profiles|Type your %{confirmationValue} to confirm:'),
  },
};
</script>

<template>
  <gl-modal
    modal-id="delete-account-modal"
    title="Profiles"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="onSubmit"
  >
    <p>
      <gl-sprintf :message="deleteMessage">
        <template #yourAccount>
          <strong>{{ s__('Profiles|your account') }}</strong>
        </template>

        <template #deleteAccount>
          <strong>{{ s__('Profiles|Delete account') }}</strong>
        </template>
      </gl-sprintf>
    </p>

    <form ref="form" :action="actionUrl" method="post">
      <input type="hidden" name="_method" value="delete" />
      <input :value="csrfToken" type="hidden" name="authenticity_token" />

      <p id="input-label">
        <gl-sprintf :message="$options.i18n.inputLabel">
          <template #confirmationValue>
            <code>{{ confirmationValue }}</code>
          </template>
        </gl-sprintf>
      </p>

      <input
        v-if="confirmWithPassword"
        v-model="enteredPassword"
        name="password"
        class="form-control"
        type="password"
        data-testid="password-confirmation-field"
        aria-labelledby="input-label"
      />
      <input
        v-else
        v-model="enteredUsername"
        name="username"
        class="form-control"
        type="text"
        data-testid="username-confirmation-field"
        aria-labelledby="input-label"
      />
    </form>
  </gl-modal>
</template>
