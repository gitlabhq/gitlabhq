<script>
import { GlDisclosureDropdownItem, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { sprintf, __ } from '~/locale';
import { createAlert } from '~/alert';
import { isLoggedIn } from '~/lib/utils/common_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import projectInfoQuery from 'ee_else_ce/repository/queries/project_info.query.graphql';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';
import getRefMixin from '~/repository/mixins/get_ref';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const REPLACE_BLOB_MODAL_ID = 'modal-replace-blob';

export default {
  i18n: {
    replace: __('Replace'),
    delete: __('Delete'),
    fetchError: __('An error occurred while fetching lock information, please try again.'),
  },
  replaceBlobModalId: REPLACE_BLOB_MODAL_ID,
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    DeleteBlobModal,
    UploadBlobModal,
    LockFileDropdownItem: () =>
      import('ee_component/repository/components/header_area/lock_file_dropdown_item.vue'),
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
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
    isEmptyRepository: {
      type: Boolean,
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
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    projectInfo: {
      query: projectInfoQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update({ project }) {
        this.pathLocks = project?.pathLocks || DEFAULT_BLOB_INFO.pathLocks;
        this.userPermissions = project?.userPermissions;
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  data() {
    return {
      pathLocks: DEFAULT_BLOB_INFO.pathLocks,
      userPermissions: DEFAULT_BLOB_INFO.userPermissions,
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    isLoading() {
      return this.$apollo?.queries.projectInfo.loading;
    },
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
    deleteFileItem() {
      return {
        text: this.$options.i18n.delete,
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
    replaceCommitMessage() {
      return sprintf(__('Replace %{name}'), { name: this.blobInfo.name });
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
    showModal(modalId) {
      if (this.showForkSuggestion) {
        this.$emit('fork', 'view');
        return;
      }

      this.$refs[modalId].show();
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
    <gl-disclosure-dropdown-item
      :item="replaceFileItem"
      @action="showModal($options.replaceBlobModalId)"
    />
    <gl-disclosure-dropdown-item :item="deleteFileItem" @action="showModal(deleteModalId)" />
    <upload-blob-modal
      :ref="$options.replaceBlobModalId"
      :modal-id="$options.replaceBlobModalId"
      :commit-message="replaceCommitMessage"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="userPermissions.pushCode"
      :can-push-to-branch="blobInfo.canCurrentUserPushToBranch"
      :path="blobInfo.path"
      :replace-path="blobInfo.replacePath"
    />
    <delete-blob-modal
      :ref="deleteModalId"
      :delete-path="blobInfo.webPath"
      :modal-id="deleteModalId"
      :commit-message="deleteModalCommitMessage"
      :target-branch="targetBranch || ref"
      :original-branch="originalBranch || ref"
      :can-push-code="userPermissions.pushCode"
      :can-push-to-branch="blobInfo.canCurrentUserPushToBranch"
      :empty-repo="isEmptyRepository"
      :is-using-lfs="isUsingLfs"
    />
  </gl-disclosure-dropdown-group>
</template>
