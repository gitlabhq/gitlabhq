<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlIcon,
  GlModalDirective,
} from '@gitlab/ui';
import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import getRefMixin from '../mixins/get_ref';
import projectPathQuery from '../queries/project_path.query.graphql';
import projectShortPathQuery from '../queries/project_short_path.query.graphql';
import UploadBlobModal from './upload_blob_modal.vue';
import NewDirectoryModal from './new_directory_modal.vue';

const ROW_TYPES = {
  header: 'header',
  divider: 'divider',
};

const UPLOAD_BLOB_MODAL_ID = 'modal-upload-blob';
const NEW_DIRECTORY_MODAL_ID = 'modal-new-directory';

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlIcon,
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
              to,
            });
          },
          [
            {
              name: this.projectShortPath,
              path: '/',
              to: `/-/tree/${this.escapedRef}/`,
            },
          ],
        );
    },
    canCreateMrFromFork() {
      return this.userPermissions?.forkProject && this.userPermissions?.createMergeRequestIn;
    },
    showUploadModal() {
      return this.canEditTree && !this.$apollo.queries.userPermissions.loading;
    },
    showNewDirectoryModal() {
      return this.canEditTree && !this.$apollo.queries.userPermissions.loading;
    },
    dropdownItems() {
      const items = [];

      if (this.canEditTree) {
        items.push(
          {
            type: ROW_TYPES.header,
            text: __('This directory'),
          },
          {
            attrs: {
              href: `${this.newBlobPath}/${
                this.currentPath ? encodeURIComponent(this.currentPath) : ''
              }`,
              'data-qa-selector': 'new_file_menu_item',
            },
            text: __('New file'),
          },
          {
            attrs: {
              href: '#modal-upload-blob',
            },
            text: __('Upload file'),
            modalId: UPLOAD_BLOB_MODAL_ID,
          },
        );

        items.push({
          attrs: {
            href: '#modal-create-new-dir',
          },
          text: __('New directory'),
          modalId: NEW_DIRECTORY_MODAL_ID,
        });
      } else if (this.canCreateMrFromFork) {
        items.push(
          {
            attrs: {
              href: this.forkNewBlobPath,
              'data-method': 'post',
            },
            text: __('New file'),
          },
          {
            attrs: {
              href: this.forkUploadBlobPath,
              'data-method': 'post',
            },
            text: __('Upload file'),
          },
          {
            attrs: {
              href: this.forkNewDirectoryPath,
              'data-method': 'post',
            },
            text: __('New directory'),
          },
        );
      }

      if (this.userPermissions?.pushCode) {
        items.push(
          {
            type: ROW_TYPES.divider,
          },
          {
            type: ROW_TYPES.header,
            text: __('This repository'),
          },
          {
            attrs: {
              href: this.newBranchPath,
            },
            text: __('New branch'),
          },
          {
            attrs: {
              href: this.newTagPath,
            },
            text: __('New tag'),
          },
        );
      }

      return items;
    },
    isBlobPath() {
      return this.$route.name === 'blobPath' || this.$route.name === 'blobPathDecoded';
    },
    renderAddToTreeDropdown() {
      return !this.isBlobPath && (this.canCollaborate || this.canCreateMrFromFork);
    },
    newDirectoryPath() {
      return joinPaths(this.newDirPath, this.currentPath);
    },
  },
  methods: {
    isLast(i) {
      return i === this.pathLinks.length - 1;
    },
    getComponent(type) {
      switch (type) {
        case ROW_TYPES.divider:
          return 'gl-dropdown-divider';
        case ROW_TYPES.header:
          return 'gl-dropdown-section-header';
        default:
          return 'gl-dropdown-item';
      }
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
        <gl-dropdown
          toggle-class="add-to-tree gl-ml-2"
          data-testid="add-to-tree"
          data-qa-selector="add_to_tree_dropdown"
        >
          <template #button-content>
            <span class="sr-only">{{ __('Add to tree') }}</span>
            <gl-icon name="plus" :size="16" class="float-left" />
            <gl-icon name="chevron-down" :size="16" class="float-left" />
          </template>
          <template v-for="(item, i) in dropdownItems">
            <component
              :is="getComponent(item.type)"
              :key="i"
              v-bind="item.attrs"
              v-gl-modal="item.modalId || null"
            >
              {{ item.text }}
            </component>
          </template>
        </gl-dropdown>
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
