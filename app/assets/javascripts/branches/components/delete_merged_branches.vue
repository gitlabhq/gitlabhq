<script>
import {
  GlDisclosureDropdown,
  GlButton,
  GlFormInput,
  GlModal,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
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
    'Branches|Please type the following to confirm: %{codeStart}delete%{codeEnd}.',
  ),
  cancelButtonText: __('Cancel'),
  actionsToggleText: __('More actions'),
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
  directives: {
    GlTooltip: GlTooltipDirective,
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
      enteredText: '',
      formId: 'delete-merged-branches-form',
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
            'data-testid': 'delete-merged-branches-button',
            class: '!gl-text-red-500',
          },
        },
      ];
    },
  },
  methods: {
    openModal() {
      this.$refs.modal.show();
    },
    closeModal() {
      this.$refs.modal.hide();
    },
    resetModal() {
      this.enteredText = '';
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      v-gl-tooltip.hover.top="{
        title: $options.i18n.actionsToggleText,
        boundary: 'viewport',
      }"
      :toggle-text="$options.i18n.actionsToggleText"
      text-sr-only
      icon="ellipsis_v"
      category="tertiary"
      no-caret
      placement="bottom-end"
      class="gl-hidden md:!gl-block"
      :items="dropdownItems"
    />
    <gl-button
      data-testid="delete-merged-branches-button"
      category="secondary"
      variant="danger"
      class="gl-block md:!gl-hidden"
      @click="openModal"
    >
      {{ $options.i18n.deleteButtonText }}
    </gl-button>
    <gl-modal
      ref="modal"
      size="sm"
      modal-id="delete-merged-branches"
      :title="$options.i18n.modalTitle"
      @hidden="resetModal"
    >
      <form :id="formId" :action="formPath" method="post">
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
            type="text"
            width="sm"
            class="gl-mt-2"
            aria-labelledby="input-label"
            required
            autocomplete="off"
          />
        </p>

        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      </form>

      <template #modal-footer>
        <div class="gl-m-0 gl-mr-3 gl-flex gl-flex-row gl-flex-wrap gl-justify-end">
          <gl-button data-testid="delete-merged-branches-cancel-button" @click="closeModal">
            {{ $options.i18n.cancelButtonText }}
          </gl-button>
          <gl-button
            ref="deleteMergedBrancesButton"
            :disabled="isDeleteButtonDisabled"
            :form="formId"
            variant="danger"
            type="submit"
            data-testid="delete-merged-branches-confirmation-button"
          >
            {{ $options.i18n.deleteButtonText }}
          </gl-button>
        </div>
      </template>
    </gl-modal>
  </div>
</template>
