<script>
import { GlButton, GlDrawer, GlLink, GlFormTextarea, GlModal, GlFormInput } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { visitUrl } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';
import { createAlert, VARIANT_WARNING } from '~/alert';
import removeBlobsMutation from './graphql/mutations/remove_blobs.mutation.graphql';

const trackingMixin = InternalEvents.mixin();

export const BLOB_OID_LENGTH = 40;

const i18n = {
  removeBlobs: s__('ProjectMaintenance|Remove blobs'),
  description: s__(
    'ProjectMaintenance|Enter a list of object IDs to be removed to reduce repository size.',
  ),
  helpLink: s__('ProjectMaintenance|How do I get a list of object IDs?'),
  label: s__('ProjectMaintenance|Blob IDs to remove'),
  helpText: s__('ProjectMaintenance|Enter multiple entries on separate lines.'),
  modalPrimaryText: s__('ProjectMaintenance|Yes, remove blobs'),
  modalCancelText: s__('ProjectMaintenance|Cancel'),
  modalContent: s__(
    'ProjectMaintenance|Removing blobs by ID cannot be undone. Are you sure you want to continue?',
  ),
  modalConfirm: s__('ProjectMaintenance|Enter the following to confirm:'),
  removeBlobsError: s__('ProjectMaintenance|Something went wrong while removing blobs.'),
  successAlertTitle: s__('ProjectMaintenance|Blobs removed'),
  successAlertContent: s__(
    'ProjectMaintenance|Run housekeeping to remove old versions from repository.',
  ),
  successAlertButtonText: s__('ProjectMaintenance|Go to housekeeping'),
};

export default {
  i18n,
  DRAWER_Z_INDEX,
  removeBlobsHelpLink: helpPagePath('/user/project/repository/reducing_the_repo_size_using_git', {
    anchor: 'get-a-list-of-object-ids',
  }),
  modalCancel: { text: i18n.modalCancelText },
  components: { GlButton, GlDrawer, GlLink, GlFormTextarea, GlModal, GlFormInput },
  mixins: [trackingMixin],
  inject: { projectPath: { default: '' }, housekeepingPath: { default: '' } },
  data() {
    return {
      isDrawerOpen: false,
      blobIDs: null,
      showConfirmationModal: false,
      confirmInput: null,
      isLoading: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    blobOids() {
      return this.blobIDs?.split('\n') || [];
    },
    isValid() {
      return this.blobOids.length && this.blobOids.every((s) => s.length >= BLOB_OID_LENGTH);
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
      this.blobIDs = null;
      this.isDrawerOpen = false;
    },
    clearConfirmInput() {
      this.confirmInput = null;
    },
    removeBlobs() {
      this.showConfirmationModal = true;
    },
    removeBlobsConfirm() {
      this.isLoading = true;
      this.trackEvent('click_remove_blob_button_repository_settings');
      this.$apollo
        .mutate({
          mutation: removeBlobsMutation,
          variables: {
            blobOids: this.blobOids,
            projectPath: this.projectPath,
          },
        })
        .then(({ data: { projectBlobsRemove: { errors } = {} } = {} }) => {
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
      createAlert({ message: i18n.removeBlobsError, captureError: true });
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
      >{{ $options.i18n.removeBlobs }}</gl-button
    >

    <gl-drawer
      :header-height="getDrawerHeaderHeight"
      :open="isDrawerOpen"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDrawer"
    >
      <template #title>
        <h4 class="gl-m-0">{{ $options.i18n.removeBlobs }}</h4>
      </template>

      <div>
        <p class="gl-text-secondary">
          {{ $options.i18n.description }}
          <gl-link :href="$options.removeBlobsHelpLink" target="_blank">{{
            $options.i18n.helpLink
          }}</gl-link>
        </p>
        <label for="blobs">{{ $options.i18n.label }}</label>
        <gl-form-textarea
          id="blobs"
          v-model.trim="blobIDs"
          class="!gl-font-monospace gl-mb-3"
          :disabled="isLoading"
          autofocus
        />

        <p class="gl-text-gray-400">{{ $options.i18n.helpText }}</p>

        <gl-button
          data-testid="remove-blobs"
          variant="danger"
          :disabled="!isValid"
          :loading="isLoading"
          @click="removeBlobs"
          >{{ $options.i18n.removeBlobs }}</gl-button
        >
      </div>
    </gl-drawer>

    <gl-modal
      v-model="showConfirmationModal"
      :title="$options.i18n.removeBlobs"
      modal-id="remove-blobs-confirmation-modal"
      :action-cancel="$options.modalCancel"
      :action-primary="modalPrimary"
      @hide="clearConfirmInput"
      @primary="removeBlobsConfirm"
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
