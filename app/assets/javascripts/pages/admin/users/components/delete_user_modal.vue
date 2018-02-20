<script>
  import axios from '~/lib/utils/axios_utils';
  import _ from 'underscore';
  import ConfirmationInput from '~/vue_shared/components/confirmation_input.vue';
  import GlModal from '~/vue_shared/components/gl_modal.vue';
  import { s__, sprintf } from '~/locale';

  export default {
    components: {
      ConfirmationInput,
      GlModal,
    },
    props: {
      deleteUserUrl: {
        type: String,
        required: false,
        default: '',
      },
      blockUserUrl: {
        type: String,
        required: false,
        default: '',
      },
      deleteContributions: {
        type: Boolean,
        required: false,
        default: false,
      },
      username: {
        type: String,
        required: false,
        default: '',
      },
    },
    computed: {
      id() {
        return 'delete-user-modal';
      },
      title() {
        const keepContributionsTitle = s__('AdminUsers|Delete User %{username}?');
        const deleteContributionsTitle = s__('AdminUsers|Delete User %{username} and contributions?');

        return sprintf(
          this.deleteContributions ? deleteContributionsTitle : keepContributionsTitle, {
            username: `'${_.escape(this.username)}'`,
          }, false);
      },
      text() {
        const keepContributionsText = s__(`AdminArea|
          You are about to permanently delete the user %{username}.
          This will delete all of the issues, merge requests, and groups linked to them.
          To avoid data loss, consider using the %{strong_start}block user%{strong_end} feature instead.
          Once you %{strong_start}Delete user%{strong_end}, it cannot be undone or recovered.`);

        const deleteContributionsText = s__(`AdminArea|
          You are about to permanently delete the user %{username}.
          Issues, merge requests, and groups linked to them will be transferred to a system-wide "Ghost-user".
          To avoid data loss, consider using the %{strong_start}block user%{strong_end} feature instead.
          Once you %{strong_start}Delete user%{strong_end}, it cannot be undone or recovered.`);

        return sprintf(this.deleteContributions ? deleteContributionsText : keepContributionsText,
          {
            username: `<strong>${_.escape(this.username)}</strong>`,
            strong_start: '<strong>',
            strong_end: '</strong>',
          },
          false,
        );
      },
      primaryButtonLabel() {
        const keepContributionsLabel = s__('AdminUsers|Delete user');
        const deleteContributionsLabel = s__('AdminUsers|Delete user and contributions');

        return this.deleteContributions ? deleteContributionsLabel : keepContributionsLabel;
      },
      secondaryButtonLabel() {
        return s__('AdminUsers|Block user');
      },
    },
    methods: {
      clearInput() {
        this.$refs.input.$emit('clear');
      },
      onConfirmed(isConfirmed) {
        this.$refs.modal.$emit('toggleCanSubmit', isConfirmed);
      },
      onSecondaryAction() {
        return axios.put(this.blockUserUrl)
          .then(() => this.clearInput);
      },
      onSubmit() {
        return axios.delete(this.deleteUserUrl)
          .then(() => this.clearInput);
      },
    },
    mounted() {
      clearInput();
    }
  };
</script>

<template>
  <gl-modal
    ref="modal"
    :id="id"
    :header-title-text="title"
    footer-primary-button-variant="danger"
    :footer-primary-button-text="primaryButtonLabel"
    footer-secondary-button-variant="warning"
    :footer-secondary-button-text="secondaryButtonLabel"
    @submit="onSubmit"
    @secondaryAction="onSecondaryAction"
    @cancel="clearInput"
  >
    <p v-html="text"></p>
    <confirmation-input
      ref="input"
      :id="`${this.id}-input`"
      :confirmation-value="username"
      @confirmed="onConfirmed"
    />
  </gl-modal>
</template>
