<script>
import { GlDisclosureDropdown, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';

export default {
  components: {
    GlDisclosureDropdown,
    UploadBlobModal,
    NewDirectoryModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    currentPath: {
      type: String,
      required: false,
      default: '',
    },
    canEditTree: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCollaborate: {
      type: Boolean,
      required: false,
      default: false,
    },
    newBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    forkNewBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    forkNewDirectoryPath: {
      type: String,
      required: false,
      default: null,
    },
    forkUploadBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    newBranchPath: {
      type: String,
      required: false,
      default: null,
    },
    newTagPath: {
      type: String,
      required: false,
      default: null,
    },
    uploadPath: {
      type: String,
      required: false,
      default: '',
    },
    newDirPath: {
      type: String,
      required: false,
      default: '',
    },
    selectedBranch: {
      type: String,
      required: false,
      default: '',
    },
    originalBranch: {
      type: String,
      required: false,
      default: '',
    },
    canPushCode: {
      type: Boolean,
      required: false,
      default: false,
    },
    canPushToBranch: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
    userPermissions: {
      query: permissionsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: (data) => data.project?.userPermissions,
    },
  },
  data() {
    return {
      projectPath: '',
      userPermissions: {},
    };
  },
  computed: {
    uploadBlobModalId() {
      return uniqueId('modal-upload-blob');
    },
    newDirectoryModalId() {
      return uniqueId('modal-new-directory');
    },
    canCreateMrFromFork() {
      return this.userPermissions?.forkProject && this.userPermissions?.createMergeRequestIn;
    },
    hasPushCodePermission() {
      return this.userPermissions?.pushCode;
    },
    dropdownDirectoryItems() {
      if (this.canEditTree) {
        return [
          {
            text: s__('Repository|New file'),
            href: joinPaths(
              this.newBlobPath,
              this.currentPath ? encodeURIComponent(this.currentPath) : '',
            ),
            extraAttrs: {
              'data-testid': 'new-file-menu-item',
            },
          },
          {
            text: s__('Repository|Upload file'),
            action: () => this.$root.$emit(BV_SHOW_MODAL, this.uploadBlobModalId),
          },
          {
            text: s__('Repository|New directory'),
            action: () => this.$root.$emit(BV_SHOW_MODAL, this.newDirectoryModalId),
          },
        ];
      }

      if (this.canCreateMrFromFork) {
        return [
          {
            text: s__('Repository|New file'),
            href: this.forkNewBlobPath,
            extraAttrs: {
              'data-method': 'post',
            },
          },
          {
            text: s__('Repository|Upload file'),
            href: this.forkUploadBlobPath,
            extraAttrs: {
              'data-method': 'post',
            },
          },
          {
            text: s__('Repository|New directory'),
            href: this.forkNewDirectoryPath,
            extraAttrs: {
              'data-method': 'post',
            },
          },
        ];
      }

      return [];
    },
    dropdownRepositoryItems() {
      if (!this.hasPushCodePermission) return [];
      return [
        {
          text: s__('Repository|New branch'),
          href: this.newBranchPath,
        },
        {
          text: s__('Repository|New tag'),
          href: this.newTagPath,
        },
      ];
    },
    dropdownItems() {
      if (!this.canCollaborate && !this.canCreateMrFromFork) return [];
      return [
        this.dropdownDirectoryItems?.length && {
          name: s__('Repository|This directory'),
          items: this.dropdownDirectoryItems,
        },
        this.dropdownRepositoryItems?.length && {
          name: s__('Repository|This repository'),
          items: this.dropdownRepositoryItems,
        },
      ].filter(Boolean);
    },
    renderAddToTreeDropdown() {
      return this.dropdownItems.length;
    },
    showUploadModal() {
      return this.canEditTree && !this.$apollo.queries.userPermissions.loading;
    },
    showNewDirectoryModal() {
      return this.canEditTree && !this.$apollo.queries.userPermissions.loading;
    },
    newDirectoryPath() {
      return joinPaths(this.newDirPath, this.currentPath);
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      v-if="renderAddToTreeDropdown"
      :toggle-text="__('Add to tree')"
      toggle-class="add-to-tree"
      data-testid="add-to-tree"
      text-sr-only
      icon="plus"
      :items="dropdownItems"
    />
    <upload-blob-modal
      v-if="showUploadModal"
      :modal-id="uploadBlobModalId"
      :commit-message="__('Upload New File')"
      :target-branch="selectedBranch"
      :original-branch="originalBranch"
      :can-push-code="canPushCode"
      :can-push-to-branch="canPushToBranch"
      :path="uploadPath"
    />
    <new-directory-modal
      v-if="showNewDirectoryModal"
      :can-push-code="canPushCode"
      :can-push-to-branch="canPushToBranch"
      :modal-id="newDirectoryModalId"
      :target-branch="selectedBranch"
      :original-branch="originalBranch"
      :path="newDirectoryPath"
    />
  </div>
</template>
