<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlDisclosureDropdown, GlModalDirective, GlLink } from '@gitlab/ui';
import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import { joinPaths, escapeFileUrl, buildURLwithRefType } from '~/lib/utils/url_utility';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { __ } from '~/locale';
import getRefMixin from '~/repository/mixins/get_ref';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import projectShortPathQuery from '~/repository/queries/project_short_path.query.graphql';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import featureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const UPLOAD_BLOB_MODAL_ID = 'modal-upload-blob';
const NEW_DIRECTORY_MODAL_ID = 'modal-new-directory';

export default {
  components: {
    ClipboardButton,
    GlDisclosureDropdown,
    UploadBlobModal,
    NewDirectoryModal,
    GlLink,
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
          projectPath: this.projectPath || this.projectRootPath,
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
  mixins: [getRefMixin, featureFlagMixin()],
  inject: {
    projectRootPath: {
      default: '',
    },
    isBlobView: {
      default: false,
    },
  },
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
    canPushToBranch: {
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
    currentDirectoryPath() {
      const splitPath = this.currentPath.split('/').filter((p) => p);

      if (this.isBlobPath) {
        splitPath.pop();
      }

      return joinPaths(...splitPath);
    },
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
              to: !this.isBlobView
                ? buildURLwithRefType({ path: to, refType: this.refType })
                : null,
              url: buildURLwithRefType({
                path: joinPaths(this.projectPath, to),
                refType: this.refType,
              }),
            });
          },
          [
            {
              name: this.projectShortPath,
              path: '/',
              to: !this.isBlobView
                ? buildURLwithRefType({
                    path: joinPaths('/-/tree', this.escapedRef),
                    refType: this.refType,
                  })
                : null,
              url: buildURLwithRefType({
                path: joinPaths(this.projectPath, '/-/tree', this.escapedRef),
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
    gfmCopyText() {
      return `\`${this.currentPath}\``;
    },
    showCopyButton() {
      return this.glFeatures.blobOverflowMenu && this.currentPath?.trim().length;
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
  <nav
    :aria-label="__('Files breadcrumb')"
    :data-current-path="currentDirectoryPath"
    class="js-repo-breadcrumbs gl-flex"
  >
    <ol class="breadcrumb repo-breadcrumb">
      <li v-for="(link, i) in pathLinks" :key="i" class="breadcrumb-item">
        <gl-link :to="link.to" :href="link.url" :aria-current="isLast(i) ? 'page' : null">
          <strong v-if="isLast(i)">{{ link.name }}</strong>
          <span v-else>{{ link.name }}</span>
        </gl-link>
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
    <clipboard-button
      v-if="showCopyButton"
      :text="currentPath"
      :gfm="gfmCopyText"
      :title="__('Copy file path')"
      category="tertiary"
      css-class="gl-mx-2"
    />
    <upload-blob-modal
      v-if="showUploadModal"
      :modal-id="$options.uploadBlobModalId"
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
      :modal-id="$options.newDirectoryModalId"
      :target-branch="selectedBranch"
      :original-branch="originalBranch"
      :path="newDirectoryPath"
    />
  </nav>
</template>
