<script>
import { GlDisclosureDropdownItem, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { showForkSuggestion } from '~/repository/utils/fork_suggestion_utils';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';
import getRefMixin from '~/repository/mixins/get_ref';
import ForkSuggestionModal from '~/repository/components/header_area/fork_suggestion_modal.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const REPLACE_BLOB_MODAL_ID = 'modal-replace-blob';

export default {
  name: 'CEBlobButtonGroup',
  i18n: {
    replace: __('Replace'),
  },
  replaceBlobModalId: REPLACE_BLOB_MODAL_ID,
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    ForkSuggestionModal,
    UploadBlobModal,
  },
  mixins: [getRefMixin],
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
    isUsingLfs: {
      type: Boolean,
      required: false,
      default: false,
    },
    userPermissions: {
      type: Object,
      required: true,
    },
    isReplaceDisabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isForkSuggestionModalVisible: false,
    };
  },
  computed: {
    replaceFileItem() {
      return {
        text: this.$options.i18n.replace,
        extraAttrs: {
          'data-testid': 'replace',
          disabled: this.isReplaceDisabled,
        },
      };
    },
    replaceCommitMessage() {
      return sprintf(__('Replace %{name}'), { name: this.blobInfo.name });
    },
    shouldShowForkSuggestion() {
      return showForkSuggestion(this.userPermissions, this.isUsingLfs, this.blobInfo);
    },
  },
  methods: {
    showModal() {
      if (this.shouldShowForkSuggestion) {
        this.isForkSuggestionModalVisible = true;
        return;
      }

      this.$refs[this.$options.replaceBlobModalId].show();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group bordered>
    <slot name="lock-file-item"></slot>
    <gl-disclosure-dropdown-item
      :item="replaceFileItem"
      data-testid="replace-dropdown-item"
      @action="showModal"
    />
    <fork-suggestion-modal
      :visible="isForkSuggestionModalVisible"
      :fork-path="blobInfo.forkAndViewPath"
      @hide="isForkSuggestionModalVisible = false"
    />
    <upload-blob-modal
      :ref="$options.replaceBlobModalId"
      :modal-id="$options.replaceBlobModalId"
      :commit-message="replaceCommitMessage"
      :target-branch="selectedBranch || currentRef"
      :original-branch="originalBranch || currentRef"
      :can-push-code="userPermissions.pushCode"
      :can-push-to-branch="blobInfo.canCurrentUserPushToBranch"
      :path="blobInfo.path"
      :replace-path="blobInfo.replacePath"
    />
  </gl-disclosure-dropdown-group>
</template>
