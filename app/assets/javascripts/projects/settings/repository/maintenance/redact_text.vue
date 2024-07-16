<script>
import { GlButton, GlDrawer, GlFormTextarea, GlModal, GlFormInput, GlSprintf } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { visitUrl } from '~/lib/utils/url_utility';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';
import { createAlert, VARIANT_WARNING } from '~/alert';
import replaceTextMutation from './graphql/mutations/replace_text.mutation.graphql';

const trackingMixin = InternalEvents.mixin();

const i18n = {
  redactText: s__('ProjectMaintenance|Redact text'),
  redactMatchingStrings: s__('ProjectMaintenance|Redact matching strings'),
  removed: s__('ProjectMaintenance|REMOVED'),
  description: s__(
    'ProjectMaintenance|Redact matching instances of text in the repository. Strings will be replaced with %{removed}.',
  ),
  label: s__('ProjectMaintenance|Strings to redact'),
  helpText: s__(
    'ProjectMaintenance|Regex and glob patterns supported. Enter multiple entries on separate lines.',
  ),
  modalPrimaryText: s__('ProjectMaintenance|Yes, redact matching strings'),
  modalCancelText: s__('ProjectMaintenance|Cancel'),
  modalContent: s__(
    'ProjectMaintenance|Redacting strings does not produce a preview and cannot be undone. Are you sure you want to continue?',
  ),
  modalConfirm: s__('ProjectMaintenance|To confirm, enter the following:'),
  redactTextError: s__('ProjectMaintenance|Something went wrong while redacting text.'),
  successAlertTitle: s__('ProjectMaintenance|Text redacted'),
  successAlertContent: s__(
    'ProjectMaintenance|To remove old versions from the repository, run housekeeping.',
  ),
  successAlertButtonText: s__('ProjectMaintenance|Go to housekeeping'),
};

export default {
  i18n,
  DRAWER_Z_INDEX,
  modalCancel: { text: i18n.modalCancelText },
  components: { GlButton, GlDrawer, GlFormTextarea, GlModal, GlFormInput, GlSprintf },
  mixins: [trackingMixin],
  inject: { projectPath: { default: '' }, housekeepingPath: { default: '' } },
  data() {
    return {
      isDrawerOpen: false,
      text: null,
      showConfirmationModal: false,
      confirmInput: null,
      isLoading: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    textArray() {
      return this.text?.split('\n') || [];
    },
    isValid() {
      return this.textArray.length;
    },
    modalPrimary() {
      return {
        text: i18n.modalPrimaryText,
        attributes: { variant: 'danger', disabled: !this.isConfirmEnabled },
      };
    },
    isConfirmEnabled() {
      return this.confirmInput === this.projectPath;
    },
  },
  methods: {
    openDrawer() {
      this.isDrawerOpen = true;
    },
    closeDrawer() {
      this.text = null;
      this.isDrawerOpen = false;
    },
    clearConfirmInput() {
      this.confirmInput = null;
    },
    redactText() {
      this.showConfirmationModal = true;
    },
    redactTextConfirm() {
      this.isLoading = true;
      this.trackEvent('click_redact_text_button_repository_settings');
      this.$apollo
        .mutate({
          mutation: replaceTextMutation,
          variables: {
            replacements: this.textArray,
            projectPath: this.projectPath,
          },
        })
        .then(({ data: { projectTextReplace: { errors } = {} } = {} }) => {
          this.isLoading = false;

          if (errors?.length) {
            this.handleError();
            return;
          }

          this.closeDrawer();
          this.generateSuccessAlert();
        })
        .catch(() => {
          this.isLoading = false;
          this.handleError();
        });
    },
    generateSuccessAlert() {
      createAlert({
        title: i18n.successAlertTitle,
        message: i18n.successAlertContent,
        variant: VARIANT_WARNING,
        primaryButton: {
          text: i18n.successAlertButtonText,
          clickHandler: () => this.navigateToHousekeeping(),
        },
      });
    },
    navigateToHousekeeping() {
      visitUrl(this.housekeepingPath);
    },
    handleError() {
      createAlert({ message: i18n.redactTextError, captureError: true });
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      class="gl-mb-6"
      category="secondary"
      variant="danger"
      data-testid="drawer-trigger"
      @click="openDrawer"
      >{{ $options.i18n.redactText }}</gl-button
    >

    <gl-drawer
      :header-height="getDrawerHeaderHeight"
      :open="isDrawerOpen"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDrawer"
    >
      <template #title>
        <h4 class="gl-m-0">{{ $options.i18n.redactText }}</h4>
      </template>

      <div>
        <p class="gl-text-secondary">
          <gl-sprintf :message="$options.i18n.description">
            <template #removed>
              <code>***{{ $options.i18n.removed }}***</code>
            </template>
          </gl-sprintf>
        </p>
        <label for="text">{{ $options.i18n.label }}</label>
        <gl-form-textarea
          id="text"
          v-model.trim="text"
          class="!gl-font-monospace gl-mb-3"
          :disabled="isLoading"
          autofocus
        />

        <p class="gl-text-gray-400">{{ $options.i18n.helpText }}</p>

        <gl-button
          data-testid="redact-text"
          variant="danger"
          :disabled="!isValid"
          :loading="isLoading"
          @click="redactText"
          >{{ $options.i18n.redactMatchingStrings }}</gl-button
        >
      </div>
    </gl-drawer>

    <gl-modal
      v-model="showConfirmationModal"
      :title="$options.i18n.redactText"
      modal-id="redact-text-confirmation-modal"
      :action-cancel="$options.modalCancel"
      :action-primary="modalPrimary"
      @hide="clearConfirmInput"
      @primary="redactTextConfirm"
    >
      <p>{{ $options.i18n.modalContent }}</p>

      <p id="confirmationInstruction" class="gl-mb-0">
        {{ $options.i18n.modalConfirm }} <code>{{ projectPath }}</code>
      </p>

      <gl-form-input
        v-model="confirmInput"
        class="gl-mt-3 gl-max-w-34"
        aria-labelledby="confirmationInstruction"
      />
    </gl-modal>
  </div>
</template>
