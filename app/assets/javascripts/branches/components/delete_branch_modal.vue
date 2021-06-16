<script>
import { GlButton, GlFormInput, GlModal, GlSprintf, GlAlert } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { sprintf, s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  csrf,
  components: {
    GlModal,
    GlButton,
    GlFormInput,
    GlSprintf,
    GlAlert,
  },
  data() {
    return {
      isProtectedBranch: false,
      branchName: '',
      defaultBranchName: '',
      deletePath: '',
      merged: false,
      enteredBranchName: '',
      modalId: 'delete-branch-modal',
    };
  },
  computed: {
    title() {
      const modalTitle = this.isProtectedBranch
        ? this.$options.i18n.modalTitleProtectedBranch
        : this.$options.i18n.modalTitle;

      return sprintf(modalTitle, { branchName: this.branchName });
    },
    message() {
      const modalMessage = this.isProtectedBranch
        ? this.$options.i18n.modalMessageProtectedBranch
        : this.$options.i18n.modalMessage;

      return sprintf(modalMessage, { branchName: this.branchName });
    },
    unmergedWarning() {
      return sprintf(this.$options.i18n.unmergedWarning, {
        defaultBranchName: this.defaultBranchName,
      });
    },
    undoneWarning() {
      return sprintf(this.$options.i18n.undoneWarning, {
        buttonText: this.buttonText,
      });
    },
    confirmationText() {
      return sprintf(this.$options.i18n.confirmationText, {
        branchName: this.branchName,
      });
    },
    buttonText() {
      return this.isProtectedBranch
        ? this.$options.i18n.deleteButtonTextProtectedBranch
        : this.$options.i18n.deleteButtonText;
    },
    branchNameConfirmed() {
      return this.enteredBranchName === this.branchName;
    },
    deleteButtonDisabled() {
      return this.isProtectedBranch && !this.branchNameConfirmed;
    },
  },
  mounted() {
    eventHub.$on('openModal', this.openModal);
  },
  destroyed() {
    eventHub.$off('openModal', this.openModal);
  },
  methods: {
    openModal({ isProtectedBranch, branchName, defaultBranchName, deletePath, merged }) {
      this.isProtectedBranch = isProtectedBranch;
      this.branchName = branchName;
      this.defaultBranchName = defaultBranchName;
      this.deletePath = deletePath;
      this.merged = merged;

      this.$refs.modal.show();
    },
    submitForm() {
      this.$refs.form.submit();
    },
    closeModal() {
      this.$refs.modal.hide();
    },
  },
  i18n: {
    modalTitle: s__('Branches|Delete branch. Are you ABSOLUTELY SURE?'),
    modalTitleProtectedBranch: s__('Branches|Delete protected branch. Are you ABSOLUTELY SURE?'),
    modalMessage: s__(
      "Branches|You're about to permanently delete the branch %{strongStart}%{branchName}.%{strongEnd}",
    ),
    modalMessageProtectedBranch: s__(
      "Branches|You're about to permanently delete the protected branch %{strongStart}%{branchName}.%{strongEnd}",
    ),
    unmergedWarning: s__(
      'Branches|This branch hasn’t been merged into %{defaultBranchName}. To avoid data loss, consider merging this branch before deleting it.',
    ),
    undoneWarning: s__(
      'Branches|Once you confirm and press %{strongStart}%{buttonText},%{strongEnd} it cannot be undone or recovered.',
    ),
    cancelButtonText: s__('Branches|Cancel, keep branch'),
    confirmationText: s__(
      'Branches|Deleting the %{strongStart}%{branchName}%{strongEnd} branch cannot be undone. Are you sure?',
    ),
    confirmationTextProtectedBranch: s__('Branches|Please type the following to confirm:'),
    deleteButtonText: s__('Branches|Yes, delete branch'),
    deleteButtonTextProtectedBranch: s__('Branches|Yes, delete protected branch'),
  },
};
</script>

<template>
  <gl-modal ref="modal" size="sm" :modal-id="modalId" :title="title">
    <gl-alert class="gl-mb-5" variant="danger" :dismissible="false">
      <div data-testid="modal-message">
        <gl-sprintf :message="message">
          <template #strong="{ content }">
            <strong> {{ content }} </strong>
          </template>
        </gl-sprintf>
        <p v-if="!merged" class="gl-mb-0 gl-mt-4">
          {{ unmergedWarning }}
        </p>
      </div>
    </gl-alert>

    <form ref="form" :action="deletePath" method="post">
      <div v-if="isProtectedBranch" class="gl-mt-4">
        <p>
          <gl-sprintf :message="undoneWarning">
            <template #strong="{ content }">
              <strong> {{ content }} </strong>
            </template>
          </gl-sprintf>
        </p>
        <p>
          <gl-sprintf :message="$options.i18n.confirmationTextProtectedBranch">
            <template #strong="{ content }">
              {{ content }}
            </template>
          </gl-sprintf>
          <code class="gl-white-space-pre-wrap"> {{ branchName }} </code>
          <gl-form-input
            v-model="enteredBranchName"
            name="delete_branch_input"
            type="text"
            class="gl-mt-4"
            aria-labelledby="input-label"
            autocomplete="off"
          />
        </p>
      </div>
      <div v-else>
        <p class="gl-mt-4">
          <gl-sprintf :message="confirmationText">
            <template #strong="{ content }">
              <strong>
                {{ content }}
              </strong>
            </template>
          </gl-sprintf>
        </p>
      </div>

      <input ref="method" type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    </form>

    <template #modal-footer>
      <div class="gl-display-flex gl-flex-direction-row gl-justify-content-end gl-flex-wrap gl-m-0">
        <gl-button data-testid="delete-branch-cancel-button" @click="closeModal">
          {{ $options.i18n.cancelButtonText }}
        </gl-button>
        <div class="gl-mr-3"></div>
        <gl-button
          ref="deleteBranchButton"
          :disabled="deleteButtonDisabled"
          variant="danger"
          data-qa-selector="delete_branch_confirmation_button"
          data-testid="delete-branch-confirmation-button"
          @click="submitForm"
          >{{ buttonText }}</gl-button
        >
      </div>
    </template>
  </gl-modal>
</template>
