<script>
  import modal from '~/vue_shared/components/modal.vue';
  import { __, s__, sprintf } from '~/locale';
  import csrf from '~/lib/utils/csrf';

  export default {
    components: {
      modal,
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
            deleteAccount: `<strong>${s__('Profiles|Delete Account')}</strong>`,
          },
          false,
        );
      },
    },
    methods: {
      canSubmit() {
        if (this.confirmWithPassword) {
          return this.enteredPassword !== '';
        }

        return this.enteredUsername === this.username;
      },
      onSubmit() {
        this.$refs.form.submit();
      },
    },
  };
</script>

<template>
  <modal
    id="delete-account-modal"
    :title="s__('Profiles|Delete your account?')"
    :text="text"
    kind="danger"
    :primary-button-label="s__('Profiles|Delete account')"
    @submit="onSubmit"
    :submit-disabled="!canSubmit()">

    <template
      slot="body"
      slot-scope="props">
      <p v-html="props.text"></p>

      <form
        ref="form"
        :action="actionUrl"
        method="post">

        <input
          type="hidden"
          name="_method"
          value="delete"
        />
        <input
          type="hidden"
          name="authenticity_token"
          :value="csrfToken"
        />

        <p
          id="input-label"
          v-html="inputLabel"
        >
        </p>

        <input
          v-if="confirmWithPassword"
          name="password"
          class="form-control"
          type="password"
          v-model="enteredPassword"
          aria-labelledby="input-label"
        />
        <input
          v-else
          name="username"
          class="form-control"
          type="text"
          v-model="enteredUsername"
          aria-labelledby="input-label"
        />
      </form>
    </template>

  </modal>
</template>
