<script>
import { GlButton, GlDrawer, GlLink, GlFormTextarea, GlModal } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';

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
};

export default {
  i18n,
  DRAWER_Z_INDEX,
  removeBlobsHelpLink: helpPagePath('/user/project/repository/reducing_the_repo_size_using_git'),
  modalCancel: { text: i18n.modalCancelText },
  modalPrimary: { text: i18n.modalPrimaryText, attributes: { variant: 'danger' } },
  components: { GlButton, GlDrawer, GlLink, GlFormTextarea, GlModal },
  data() {
    return { isDrawerOpen: false, blobIDs: null, showConfirmationModal: false };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
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
      // TODO (follow-up MR): submit mutation + show alert/toast...
      this.closeDrawer();
    },
  },
};
</script>

<template>
  <div>
    <gl-button class="gl-mb-6" data-testid="drawer-trigger" @click="openDrawer">{{
      $options.i18n.removeBlobs
    }}</gl-button>

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
          autofocus
        />

        <p class="gl-text-gray-400">{{ $options.i18n.helpText }}</p>

        <gl-button
          data-testid="remove-blobs"
          variant="danger"
          :disabled="!blobIDs"
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
      :action-primary="$options.modalPrimary"
      @primary="removeBlobsConfirm"
    >
      {{ $options.i18n.modalContent }}
    </gl-modal>
  </div>
</template>
