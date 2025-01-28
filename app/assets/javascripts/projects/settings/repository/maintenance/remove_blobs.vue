<script>
import { GlButton, GlDrawer, GlLink, GlFormTextarea } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { visitUrl } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';
import { createAlert, VARIANT_WARNING } from '~/alert';
import removeBlobsMutation from './graphql/mutations/remove_blobs.mutation.graphql';
import WarningModal from './warning_modal.vue';

const trackingMixin = InternalEvents.mixin();

export const BLOB_OID_LENGTH = 40;

const i18n = {
  removeBlobs: s__('ProjectMaintenance|Remove blobs'),
  description: s__(
    'ProjectMaintenance|Enter a list of object IDs to be removed to reduce repository size.',
  ),
  helpLink: s__('ProjectMaintenance|How do I get a list of object IDs?'),
  warningHelpLink: s__('ProjectMaintenance|How does blobs removal work?'),
  label: s__('ProjectMaintenance|Blob IDs to remove'),
  helpText: s__('ProjectMaintenance|Enter multiple entries on separate lines.'),
  removeBlobsError: s__('ProjectMaintenance|Something went wrong while removing blobs.'),
  scheduledRemovalSuccessAlertTitle: s__('ProjectMaintenance|Blobs removal is scheduled.'),
  scheduledSuccessAlertContent: s__(
    'ProjectMaintenance|You will receive an email notification when the process is complete. Run housekeeping to remove old versions from repository.',
  ),
  successAlertButtonText: s__('ProjectMaintenance|Go to housekeeping'),
  warningModalTitle: s__(
    'ProjectMaintenance|You are about to permanently remove blobs from this project.',
  ),
  warningModalPrimaryText: s__('ProjectMaintenance|Yes, remove blobs'),
};

export default {
  i18n,
  DRAWER_Z_INDEX,
  removeBlobsHelpLink: helpPagePath('/user/project/repository/repository_size', {
    anchor: 'get-a-list-of-object-ids',
  }),
  removeBlobsWarningHelpLink: helpPagePath('/user/project/repository/repository_size', {
    anchor: 'remove-blobs',
  }),
  components: { GlButton, GlDrawer, GlLink, GlFormTextarea, WarningModal },
  mixins: [trackingMixin],
  inject: { projectPath: { default: '' }, housekeepingPath: { default: '' } },
  data() {
    return {
      isDrawerOpen: false,
      blobIDs: null,
      showConfirmationModal: false,
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
  },
  methods: {
    openDrawer() {
      this.isDrawerOpen = true;
    },
    closeDrawer() {
      this.blobIDs = null;
      this.isDrawerOpen = false;
    },
    removeBlobs() {
      this.showConfirmationModal = true;
    },
    removeBlobsConfirm() {
      this.isLoading = true;
      this.showConfirmationModal = false;
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
        title: this.$options.i18n.scheduledRemovalSuccessAlertTitle,
        message: this.$options.i18n.scheduledSuccessAlertContent,
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
        <p class="gl-text-subtle">
          {{ $options.i18n.description }}
          <gl-link :href="$options.removeBlobsHelpLink" target="_blank">{{
            $options.i18n.helpLink
          }}</gl-link>
        </p>
        <label for="blobs">{{ $options.i18n.label }}</label>
        <gl-form-textarea
          id="blobs"
          v-model.trim="blobIDs"
          class="gl-mb-3 !gl-font-monospace"
          :disabled="isLoading"
          autofocus
        />

        <p class="gl-text-subtle">{{ $options.i18n.helpText }}</p>

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

    <warning-modal
      :visible="showConfirmationModal"
      :title="$options.i18n.warningModalTitle"
      :primary-text="$options.i18n.warningModalPrimaryText"
      :confirm-phrase="projectPath"
      :confirm-loading="isLoading"
      @confirm="removeBlobsConfirm"
      @hide="showConfirmationModal = false"
    >
      <gl-link :href="$options.removeBlobsWarningHelpLink" target="_blank">{{
        $options.i18n.warningHelpLink
      }}</gl-link>
    </warning-modal>
  </div>
</template>
