<script>
  import axios from '~/lib/utils/axios_utils';
  import _ from 'underscore';
  import ConfirmationInputMixin from '~/vue_shared/mixins/confirmation_input_mixin.vue';
  import GlModal from '~/vue_shared/components/gl_modal.vue';
  import { s__, sprintf } from '~/locale';

  export default {
    components: {
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
      confirmationInput() {
        const username = this.username;
        return {
          mixins: [ConfirmationInputMixin],
          computed: {
            confirmationValue() {
              return username;
            },
          },
        };
      },
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
      onSecondaryAction() {
        return axios.put(this.blockUserUrl);
      },
      onSubmit() {
        return axios.delete(this.deleteUserUrl);
      },
    },
  };
</script>

<template>
  <gl-modal
    :id="id"
    :header-title-text="title"
    footer-primary-button-variant="danger"
    :footer-primary-button-text="primaryButtonLabel"
    footer-secondary-button-variant="warning"
    :footer-secondary-button-text="secondaryButtonLabel"
    :body-component="confirmationInput"
    @submit="onSubmit"
    @secondaryAction="onSecondaryAction"
  >
    <p v-html="text"></p>
  </gl-modal>
</template>
