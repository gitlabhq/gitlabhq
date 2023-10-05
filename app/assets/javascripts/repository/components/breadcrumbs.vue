<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdown, GlModalDirective } from '@gitlab/ui';
import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import { joinPaths, escapeFileUrl, buildURLwithRefType } from '~/lib/utils/url_utility';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { __ } from '~/locale';
import getRefMixin from '../mixins/get_ref';
import projectPathQuery from '../queries/project_path.query.graphql';
import projectShortPathQuery from '../queries/project_short_path.query.graphql';
import UploadBlobModal from './upload_blob_modal.vue';
import NewDirectoryModal from './new_directory_modal.vue';

const UPLOAD_BLOB_MODAL_ID = 'modal-upload-blob';
const NEW_DIRECTORY_MODAL_ID = 'modal-new-directory';

export default {
  components: {
    GlDisclosureDropdown,
    UploadBlobModal,
    NewDirectoryModal,
  },
  apollo: {
    projectShortPath: {
      query: projectShortPathQuery,
    },
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
      error(error) {
        throw error;
      },
    },
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [getRefMixin],
  props: {
    currentPath: {
      type: String,
      required: false,
      default: '',
    },
    refType: {
      type: String,
      required: false,
      default: null,
    },
    canCollaborate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canEditTree: {
      type: Boolean,
      required: false,
      default: false,
    },
    canPushCode: {
      type: Boolean,
      required: false,
      default: false,
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
  },
  uploadBlobModalId: UPLOAD_BLOB_MODAL_ID,
  newDirectoryModalId: NEW_DIRECTORY_MODAL_ID,
  data() {
    return {
      projectShortPath: '',
      projectPath: '',
      userPermissions: {},
    };
  },
  computed: {
    pathLinks() {
      return this.currentPath
        .split('/')
        .filter((p) => p !== '')
        .reduce(
          (acc, name, i) => {
            const path = joinPaths(i > 0 ? acc[i].path : '', escapeFileUrl(name));
            const isLastPath = i === this.currentPath.split('/').length - 1;
            const to =
              this.isBlobPath && isLastPath
                ? `/-/blob/${joinPaths(this.escapedRef, path)}`
                : `/-/tree/${joinPaths(this.escapedRef, path)}`;

            return acc.concat({
              name,
              path,
              to: buildURLwithRefType({ path: to, refType: this.refType }),
            });
          },
          [
            {
              name: this.projectShortPath,
              path: '/',
              to: buildURLwithRefType({
                path: joinPaths('/-/tree', this.escapedRef),
                refType: this.refType,
              }),
            },
          ],
        );
    },
    canCreateMrFromFork() {
      return this.userPermissions?.forkProject && this.userPermissions?.createMergeRequestIn;
    },
    hasPushCodePermission() {
      return this.userPermissions?.pushCode;
    },
    showUploadModal() {
      return this.canEditTree && !this.$apollo.queries.userPermissions.loading;
    },
    showNewDirectoryModal() {
      return this.canEditTree && !this.$apollo.queries.userPermissions.loading;
    },
    dropdownDirectoryItems() {
      if (this.canEditTree) {
        return [
          {
            text: __('New file'),
            href: joinPaths(
              this.newBlobPath,
              this.currentPath ? encodeURIComponent(this.currentPath) : '',
            ),
            extraAttrs: {
              'data-testid': 'new-file-menu-item',
            },
          },
          {
            text: __('Upload file'),
            action: () => this.$root.$emit(BV_SHOW_MODAL, UPLOAD_BLOB_MODAL_ID),
          },
          {
            text: __('New directory'),
            action: () => this.$root.$emit(BV_SHOW_MODAL, NEW_DIRECTORY_MODAL_ID),
          },
        ];
      }

      if (this.canCreateMrFromFork) {
        return [
          {
            text: __('New file'),
            href: this.forkNewBlobPath,
            extraAttrs: {
              'data-method': 'post',
            },
          },
          {
            text: __('Upload file'),
            href: this.forkUploadBlobPath,
            extraAttrs: {
              'data-method': 'post',
            },
          },
          {
            text: __('New directory'),
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
          text: __('New branch'),
          href: this.newBranchPath,
        },
        {
          text: __('New tag'),
          href: this.newTagPath,
        },
      ];
    },
    dropdownItems() {
      if (this.isBlobPath) return [];
      if (!this.canCollaborate && !this.canCreateMrFromFork) return [];
      return [
        this.dropdownDirectoryItems?.length && {
          name: __('This directory'),
          items: this.dropdownDirectoryItems,
        },
        this.dropdownRepositoryItems?.length && {
          name: __('This repository'),
          items: this.dropdownRepositoryItems,
        },
      ].filter(Boolean);
    },
    isBlobPath() {
      return this.$route.name === 'blobPath' || this.$route.name === 'blobPathDecoded';
    },
    renderAddToTreeDropdown() {
      return this.dropdownItems.length;
    },
    newDirectoryPath() {
      return joinPaths(this.newDirPath, this.currentPath);
    },
  },
  methods: {
    isLast(i) {
      return i === this.pathLinks.length - 1;
    },
  },
};
</script>

<template>
  <nav :aria-label="__('Files breadcrumb')">
    <ol class="breadcrumb repo-breadcrumb">
      <li v-for="(link, i) in pathLinks" :key="i" class="breadcrumb-item">
        <router-link :to="link.to" :aria-current="isLast(i) ? 'page' : null">
          {{ link.name }}
        </router-link>
      </li>
      <li v-if="renderAddToTreeDropdown" class="breadcrumb-item">
        <gl-disclosure-dropdown
          :toggle-text="__('Add to tree')"
          toggle-class="add-to-tree gl-ml-2"
          data-testid="add-to-tree"
          text-sr-only
          icon="plus"
          :items="dropdownItems"
        />
      </li>
    </ol>
    <upload-blob-modal
      v-if="showUploadModal"
      :modal-id="$options.uploadBlobModalId"
      :commit-message="__('Upload New File')"
      :target-branch="selectedBranch"
      :original-branch="originalBranch"
      :can-push-code="canPushCode"
      :path="uploadPath"
    />
    <new-directory-modal
      v-if="showNewDirectoryModal"
      :can-push-code="canPushCode"
      :modal-id="$options.newDirectoryModalId"
      :commit-message="__('Add new directory')"
      :target-branch="selectedBranch"
      :original-branch="originalBranch"
      :path="newDirectoryPath"
    />
  </nav>
</template>
