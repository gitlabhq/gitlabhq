<script>
import { GlDisclosureDropdown, GlButton, GlFormInput, GlModal, GlSprintf } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { sprintf, s__, __ } from '~/locale';

export const i18n = {
  deleteButtonText: s__('Branches|Delete merged branches'),
  modalTitle: s__('Branches|Delete all merged branches?'),
  modalMessage: s__(
    'Branches|You are about to %{strongStart}delete all branches%{strongEnd} that were merged into %{codeStart}%{defaultBranch}%{codeEnd}.',
  ),
  notVisibleBranchesWarning: s__(
    'Branches|This may include merged branches that are not visible on the current screen.',
  ),
  protectedBranchWarning: s__(
    "Branches|A branch won't be deleted if it is protected or associated with an open merge request.",
  ),
  permanentEffectWarning: s__(
    'Branches|This bulk action is %{strongStart}permanent and cannot be undone or recovered%{strongEnd}.',
  ),
  confirmationMessage: s__(
    'Branches|Plese type the following to confirm: %{codeStart}delete%{codeEnd}.',
  ),
  cancelButtonText: __('Cancel'),
};

export default {
  csrf,
  components: {
    GlDisclosureDropdown,
    GlButton,
    GlModal,
    GlFormInput,
    GlSprintf,
  },
  props: {
    formPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      areAllBranchesVisible: false,
      enteredText: '',
    };
  },
  computed: {
    modalMessage() {
      return sprintf(this.$options.i18n.modalMessage, {
        defaultBranch: this.defaultBranch,
      });
    },
    isDeletingConfirmed() {
      return this.enteredText.trim().toLowerCase() === 'delete';
    },
    isDeleteButtonDisabled() {
      return !this.isDeletingConfirmed;
    },
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.deleteButtonText,
          action: () => {
            this.openModal();
          },
          extraAttrs: {
            'data-qa-selector': 'delete_merged_branches_button',
            class: 'gl-text-red-500!',
          },
        },
      ];
    },
  },
  methods: {
    openModal() {
      this.$refs.modal.show();
    },
    submitForm() {
      if (!this.isDeleteButtonDisabled) {
        this.$refs.form.submit();
      }
    },
    closeModal() {
      this.$refs.modal.hide();
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      :toggle-text="$options.i18n.actionsToggleText"
      text-sr-only
      icon="ellipsis_v"
      category="tertiary"
      no-caret
      placement="right"
      data-qa-selector="delete_merged_branches_dropdown_button"
      :items="dropdownItems"
    />
    <gl-modal
      ref="modal"
      size="sm"
      modal-id="delete-merged-branches"
      :title="$options.i18n.modalTitle"
    >
      <form ref="form" :action="formPath" method="post" @submit.prevent>
        <p>
          <gl-sprintf :message="modalMessage">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </p>
        <p>
          {{ $options.i18n.notVisibleBranchesWarning }}
        </p>
        <p>
          {{ $options.i18n.protectedBranchWarning }}
        </p>
        <p>
          <gl-sprintf :message="$options.i18n.permanentEffectWarning">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <p>
          <gl-sprintf :message="$options.i18n.confirmationMessage">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
          <gl-form-input
            v-model="enteredText"
            data-qa-selector="delete_merged_branches_input"
            type="text"
            size="sm"
            class="gl-mt-2"
            aria-labelledby="input-label"
            autocomplete="off"
            @keyup.enter="submitForm"
          />
        </p>

        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      </form>

      <template #modal-footer>
        <div
          class="gl-display-flex gl-flex-direction-row gl-justify-content-end gl-flex-wrap gl-m-0 gl-mr-3"
        >
          <gl-button data-testid="delete-merged-branches-cancel-button" @click="closeModal">
            {{ $options.i18n.cancelButtonText }}
          </gl-button>
          <gl-button
            ref="deleteMergedBrancesButton"
            :disabled="isDeleteButtonDisabled"
            variant="danger"
            data-qa-selector="delete_merged_branches_confirmation_button"
            data-testid="delete-merged-branches-confirmation-button"
            @click="submitForm"
            >{{ $options.i18n.deleteButtonText }}</gl-button
          >
        </div>
      </template>
    </gl-modal>
  </div>
</template>
