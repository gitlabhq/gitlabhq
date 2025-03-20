<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { sprintf, __ } from '~/locale';
import { showForkSuggestion } from '~/repository/utils/fork_suggestion_utils';
import ForkSuggestionModal from '~/repository/components/header_area/fork_suggestion_modal.vue';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';

export default {
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    ForkSuggestionModal,
    DeleteBlobModal,
  },
  inject: {
    selectedBranch: {
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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isModalVisible: false,
    };
  },
  computed: {
    deleteFileItem() {
      return {
        text: __('Delete'),
        extraAttrs: {
          'data-testid': 'delete',
          disabled: this.disabled,
        },
      };
    },
    deleteModalId() {
      return uniqueId('delete-modal');
    },
    deleteModalCommitMessage() {
      return sprintf(__('Delete %{name}'), { name: this.blobInfo.name });
    },
    shouldShowForkSuggestion() {
      return showForkSuggestion(this.userPermissions, this.isUsingLfs, this.blobInfo);
    },
  },
  methods: {
    showModal() {
      if (this.disabled) {
        return;
      }

      if (this.shouldShowForkSuggestion) {
        this.isModalVisible = true;
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
    <fork-suggestion-modal
      :visible="isModalVisible"
      :fork-path="blobInfo.forkAndViewPath"
      @hide="isModalVisible = false"
    />
    <delete-blob-modal
      :ref="deleteModalId"
      :delete-path="blobInfo.webPath"
      :modal-id="deleteModalId"
      :commit-message="deleteModalCommitMessage"
      :target-branch="selectedBranch || currentRef"
      :original-branch="originalBranch || currentRef"
      :can-push-code="userPermissions.pushCode"
      :can-push-to-branch="blobInfo.canCurrentUserPushToBranch"
      :empty-repo="isEmptyRepository"
      :is-using-lfs="isUsingLfs"
    />
  </gl-disclosure-dropdown-group>
</template>
