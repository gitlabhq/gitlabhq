<script>
  import axios from '~/lib/utils/axios_utils';
  import modal from '~/vue_shared/components/modal.vue';
  import confirmationInput from '~/vue_shared/components/confirmation_input.vue';
  import { s__, sprintf } from '~/locale';
  import { redirectTo } from '~/lib/utils/url_utility';
  import Flash from '~/flash';
  import eventHub from '../shared/event_hub';

  export default {
    components: {
      modal,
      confirmationInput,
    },
    props: {
      id: {
        type: String,
        required: false,
        default: 'delete-branch-modal',
      },
      branchName: {
        required: true,
        type: String,
      },
      deletePath: {
        required: true,
        type: String,
      },
      isMerged: {
        required: true,
        type: Boolean,
      },
      isProtected: {
        required: true,
        type: Boolean,
      },
      rootRef: {
        required: true,
        type: String,
      },
      redirectUrl: {
        required: true,
        type: String,
      },
    },
    computed: {
      title() {
        const protectedTitle = sprintf(s__(`Branches|
        Delete protected branch '%{branchName}'`), { branchName: this.branchName });
        const normalTitle = sprintf(s__(`Branches|
        Delete branch '%{branchName}'`), { branchName: this.branchName });

        return this.isProtected ? protectedTitle : normalTitle;
      },
      text() {
        const protectedBranch = sprintf(`<p>You’re about to permanently 
        delete the protected branch <strong>%{branchName}.</strong></p>`,
          {
            branchName: this.branchName,
          });
        const whenNotMerged = sprintf(`<p>This branch hasn’t been merged into <span class='ref-name'>%{rootRef}</span>
        To avoid data loss, consider merging this branch before deleting it.</p>`,
          {
            rootRef: this.rootRef,
          });
        const finalWarning = sprintf(`<p>Once you confirm and press
        <strong>%{buttonText}</strong>, it cannot be undone or recovered.</p>`,
          {
            buttonText: this.buttonText,
          });
        let text = sprintf(s__(`Branches|
        Deleting the '%{branchName}' branch cannot be undone. Are you sure?`),
          {
            branchName: this.branchName,
          });

        if (this.isProtected) {
          text = !this.isMerged ?
          sprintf(s__(`Branches|
          %{protectedBranch} %{whenNotMerged} %{finalWarning}`),
            {
              protectedBranch,
              whenNotMerged,
              finalWarning,
            },
            false) :
          sprintf(s__(`Branches|
          %{protectedBranch} %{finalWarning}`),
            {
              protectedBranch,
              finalWarning,
            },
            false);
        }

        return text;
      },
      buttonText() {
        return this.isProtected ? s__('Branches|Delete protected branch') : s__('Branches|Delete branch');
      },
      canSubmit() {
        let enableDeleteButton = this.$refs.confirmation &&
        this.$refs.confirmation.hasCorrectValue();

        enableDeleteButton = this.isProtected ? enableDeleteButton : true;
        return !enableDeleteButton;
      },
    },
    methods: {
      onSubmit() {
        eventHub.$emit('deleteBranchModal.requestStarted', this.deletePath);
        axios.delete(this.deletePath)
          .then(() => {
            eventHub.$emit('deleteBranchModal.requestFinished', { deletePath: this.deletePath, successful: true });
            redirectTo(this.redirectUrl);
          })
          .catch((error) => {
            eventHub.$emit('deleteBranchModal.requestFinished', { deletePath: this.deletePath, successful: false });
            Flash(sprintf(s__(`Branches|
            An error has ocurred when deleting the branch %{branchName}`), { branchName: this.branchName }));
            throw error;
          });
      },
    },
  };
</script>
<template>
  <modal
    id="delete-branch-modal"
    :title="title"
    :text="text"
    kind="danger"
    :primary-button-label="buttonText"
    @submit="onSubmit"
    :submit-disabled="canSubmit">

    <template
      slot="body"
      slot-scope="props">
      <p v-html="props.text"></p>

      <confirmation-input
        ref="confirmation"
        :input-id="`${id}-input`"
        confirmation-key="branch-name"
        :confirmation-value="branchName"
        v-show="isProtected"
      />
    </template>
  </modal>
</template>
