<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { sprintf, __ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';

export default {
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    DeleteBlobModal,
  },
  inject: {
    targetBranch: {
      default: '',
    },
    originalBranch: {
      default: '',
    },
    blobInfo: {
      default: () => DEFAULT_BLOB_INFO.repository.blobs.nodes[0],
    },
  },
  props: {
    currentRef: {
      type: String,
      required: true,
    },
    isEmptyRepository: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUsingLfs: {
      type: Boolean,
      required: false,
      default: false,
    },
    userPermissions: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    deleteFileItem() {
      return {
        text: __('Delete'),
        extraAttrs: {
          'data-testid': 'delete',
          // a temporary solution before resolving https://gitlab.com/gitlab-org/gitlab/-/issues/450774#note_2319974833
          disabled: this.showForkSuggestion,
        },
      };
    },
    deleteModalId() {
      return uniqueId('delete-modal');
    },
    deleteModalCommitMessage() {
      return sprintf(__('Delete %{name}'), { name: this.blobInfo.name });
    },
    canFork() {
      const { createMergeRequestIn, forkProject } = this.userPermissions;

      return this.isLoggedIn && !this.isUsingLfs && createMergeRequestIn && forkProject;
    },
    showSingleFileEditorForkSuggestion() {
      return this.canFork && !this.blobInfo.canModifyBlob;
    },
    showWebIdeForkSuggestion() {
      return this.canFork && !this.blobInfo.canModifyBlobWithWebIde;
    },
    showForkSuggestion() {
      return this.showSingleFileEditorForkSuggestion || this.showWebIdeForkSuggestion;
    },
  },
  methods: {
    showModal() {
      if (this.showForkSuggestion) {
        this.$emit('fork', 'view');
        return;
      }

      this.$refs[this.deleteModalId].show();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group bordered>
    <gl-disclosure-dropdown-item :item="deleteFileItem" variant="danger" @action="showModal" />
    <delete-blob-modal
      :ref="deleteModalId"
      :delete-path="blobInfo.webPath"
      :modal-id="deleteModalId"
      :commit-message="deleteModalCommitMessage"
      :target-branch="targetBranch || currentRef"
      :original-branch="originalBranch || currentRef"
      :can-push-code="userPermissions.pushCode"
      :can-push-to-branch="blobInfo.canCurrentUserPushToBranch"
      :empty-repo="isEmptyRepository"
      :is-using-lfs="isUsingLfs"
    />
  </gl-disclosure-dropdown-group>
</template>
