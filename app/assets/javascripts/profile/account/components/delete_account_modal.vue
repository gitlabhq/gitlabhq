<script>
  import popupDialog from '../../../vue_shared/components/popup_dialog.vue';
  import { __, s__, sprintf } from '../../../locale';
  import csrf from '../../../lib/utils/csrf';

  export default {
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
        isOpen: false,
      };
    },
    components: {
      popupDialog,
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
      onSubmit(status) {
        if (status) {
          if (!this.canSubmit()) {
            return;
          }

          this.$refs.form.submit();
        }

        this.toggleOpen(false);
      },
      toggleOpen(isOpen) {
        this.isOpen = isOpen;
      },
    },
  };
</script>

<template>
  <div>
    <popup-dialog
      v-if="isOpen"
      :title="s__('Profiles|Delete your account?')"
      :text="text"
      :kind="`danger ${!canSubmit() && 'disabled'}`"
      :primary-button-label="s__('Profiles|Delete account')"
      @toggle="toggleOpen"
      @submit="onSubmit">

      <template slot="body" slot-scope="props">
        <p v-html="props.text"></p>

        <form
          ref="form"
          :action="actionUrl"
          method="post">

          <input
            type="hidden"
            name="_method"
            value="delete" />
          <input
            type="hidden"
            name="authenticity_token"
            :value="csrfToken" />

          <p id="input-label" v-html="inputLabel"></p>

          <input
            v-if="confirmWithPassword"
            name="password"
            class="form-control"
            type="password"
            v-model="enteredPassword"
            aria-labelledby="input-label" />
          <input
            v-else
            name="username"
            class="form-control"
            type="text"
            v-model="enteredUsername"
            aria-labelledby="input-label" />
        </form>
      </template>

    </popup-dialog>

    <button
      type="button"
      class="btn btn-danger"
      @click="toggleOpen(true)">
      {{ s__('Profiles|Delete account') }}
    </button>
  </div>
</template>
