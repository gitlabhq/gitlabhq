<script>
import { GlDisclosureDropdownItem, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';
import getRefMixin from '~/repository/mixins/get_ref';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const REPLACE_BLOB_MODAL_ID = 'modal-replace-blob';

export default {
  i18n: {
    replace: __('Replace'),
  },
  replaceBlobModalId: REPLACE_BLOB_MODAL_ID,
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    UploadBlobModal,
    LockFileDropdownItem: () =>
      import('ee_component/repository/components/header_area/lock_file_dropdown_item.vue'),
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
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
    projectPath: {
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
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    pathLocks: {
      type: Object,
      required: false,
      default: () => DEFAULT_BLOB_INFO.pathLocks,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    replaceFileItem() {
      return {
        text: this.$options.i18n.replace,
        extraAttrs: {
          'data-testid': 'replace',
          // a temporary solution before resolving https://gitlab.com/gitlab-org/gitlab/-/issues/450774#note_2319974833
          disabled: this.showForkSuggestion,
        },
      };
    },
    replaceCommitMessage() {
      return sprintf(__('Replace %{name}'), { name: this.blobInfo.name });
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

      this.$refs[this.$options.replaceBlobModalId].show();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group>
    <lock-file-dropdown-item
      v-if="glFeatures.fileLocks"
      :name="blobInfo.name"
      :path="blobInfo.path"
      :project-path="projectPath"
      :path-locks="pathLocks"
      :user-permissions="userPermissions"
      :is-loading="isLoading"
    />
    <gl-disclosure-dropdown-item :item="replaceFileItem" @action="showModal" />
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
