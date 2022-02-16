<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getRefMixin from '../mixins/get_ref';
import blobInfoQuery from '../queries/blob_info.query.graphql';
import { DEFAULT_BLOB_INFO, TEXT_FILE_TYPE, LFS_STORAGE } from '../constants';
import BlobButtonGroup from './blob_button_group.vue';
import BlobEdit from './blob_edit.vue';
import ForkSuggestion from './fork_suggestion.vue';
import { loadViewer } from './blob_viewers';

export default {
  i18n: {
    pipelineEditor: __('Pipeline Editor'),
  },
  components: {
    BlobHeader,
    BlobEdit,
    BlobButtonGroup,
    BlobContent,
    GlLoadingIcon,
    GlButton,
    ForkSuggestion,
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
  inject: {
    originalBranch: {
      default: '',
    },
  },
  apollo: {
    project: {
      query: blobInfoQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.path,
          ref: this.originalBranch || this.ref,
          shouldFetchRawText: Boolean(this.glFeatures.highlightJs),
        };
      },
      result() {
        this.switchViewer(this.hasRichViewer ? RICH_BLOB_VIEWER : SIMPLE_BLOB_VIEWER);
      },
      error() {
        this.displayError();
      },
    },
  },
  provide() {
    return {
      blobHash: uniqueId(),
    };
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      forkTarget: null,
      legacyRichViewer: null,
      legacySimpleViewer: null,
      isBinary: false,
      isLoadingLegacyViewer: false,
      activeViewerType: SIMPLE_BLOB_VIEWER,
      project: DEFAULT_BLOB_INFO,
    };
  },
  computed: {
    isLoggedIn() {
      return isLoggedIn();
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
    isBinaryFileType() {
      return this.isBinary || this.blobInfo.simpleViewer?.fileType !== TEXT_FILE_TYPE;
    },
    blobInfo() {
      const nodes = this.project?.repository?.blobs?.nodes || [];

      return nodes[0] || {};
    },
    viewer() {
      const { richViewer, simpleViewer } = this.blobInfo;
      return this.activeViewerType === RICH_BLOB_VIEWER ? richViewer : simpleViewer;
    },
    hasRichViewer() {
      return Boolean(this.blobInfo.richViewer);
    },
    hasRenderError() {
      return Boolean(this.viewer.renderError);
    },
    blobViewer() {
      const { fileType } = this.viewer;
      return this.shouldLoadLegacyViewer ? null : loadViewer(fileType, this.isUsingLfs);
    },
    shouldLoadLegacyViewer() {
      return this.viewer.fileType === TEXT_FILE_TYPE && !this.glFeatures.highlightJs;
    },
    legacyViewerLoaded() {
      return (
        (this.activeViewerType === SIMPLE_BLOB_VIEWER && this.legacySimpleViewer) ||
        (this.activeViewerType === RICH_BLOB_VIEWER && this.legacyRichViewer)
      );
    },
    canLock() {
      const { pushCode, downloadCode } = this.project.userPermissions;
      const currentUsername = window.gon?.current_username;

      if (this.pathLockedByUser && this.pathLockedByUser.username !== currentUsername) {
        return false;
      }

      return pushCode && downloadCode;
    },
    pathLockedByUser() {
      const pathLock = this.project?.pathLocks?.nodes.find((node) => node.path === this.path);

      return pathLock ? pathLock.user : null;
    },
    showForkSuggestion() {
      const { createMergeRequestIn, forkProject } = this.project.userPermissions;
      const { canModifyBlob } = this.blobInfo;

      return this.isLoggedIn && !canModifyBlob && createMergeRequestIn && forkProject;
    },
    forkPath() {
      return this.forkTarget === 'ide'
        ? this.blobInfo.ideForkAndEditPath
        : this.blobInfo.forkAndEditPath;
    },
    isUsingLfs() {
      return this.blobInfo.storedExternally && this.blobInfo.externalStorage === LFS_STORAGE;
    },
  },
  methods: {
    loadLegacyViewer() {
      if (this.legacyViewerLoaded) {
        return;
      }

      const type = this.activeViewerType;

      this.isLoadingLegacyViewer = true;
      axios
        .get(`${this.blobInfo.webPath}?format=json&viewer=${type}`)
        .then(({ data: { html, binary } }) => {
          if (type === SIMPLE_BLOB_VIEWER) {
            this.legacySimpleViewer = html;
          } else {
            this.legacyRichViewer = html;
          }

          this.isBinary = binary;
          this.isLoadingLegacyViewer = false;
        })
        .catch(() => this.displayError());
    },
    displayError() {
      createFlash({ message: __('An error occurred while loading the file. Please try again.') });
    },
    switchViewer(newViewer) {
      this.activeViewerType = newViewer || SIMPLE_BLOB_VIEWER;

      if (!this.blobViewer) {
        this.loadLegacyViewer();
      }
    },
    editBlob(target) {
      if (this.showForkSuggestion) {
        this.setForkTarget(target);
        return;
      }

      const { ideEditPath, editBlobPath } = this.blobInfo;
      redirectTo(target === 'ide' ? ideEditPath : editBlobPath);
    },
    setForkTarget(target) {
      this.forkTarget = target;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="sm" />
    <div v-if="blobInfo && !isLoading" class="file-holder">
      <blob-header
        :blob="blobInfo"
        :hide-viewer-switcher="!hasRichViewer || isBinaryFileType || isUsingLfs"
        :is-binary="isBinaryFileType"
        :active-viewer-type="viewer.type"
        :has-render-error="hasRenderError"
        :show-path="false"
        @viewer-changed="switchViewer"
      >
        <template #actions>
          <blob-edit
            v-if="!blobInfo.archived"
            :show-edit-button="!isBinaryFileType"
            :edit-path="blobInfo.editBlobPath"
            :web-ide-path="blobInfo.ideEditPath"
            :needs-to-fork="showForkSuggestion"
            @edit="editBlob"
          />

          <gl-button
            v-if="blobInfo.pipelineEditorPath"
            class="gl-mr-3"
            category="secondary"
            variant="confirm"
            data-testid="pipeline-editor"
            :href="blobInfo.pipelineEditorPath"
          >
            {{ $options.i18n.pipelineEditor }}
          </gl-button>

          <blob-button-group
            v-if="isLoggedIn && !blobInfo.archived"
            :path="path"
            :name="blobInfo.name"
            :replace-path="blobInfo.replacePath"
            :delete-path="blobInfo.webPath"
            :can-push-code="project.userPermissions.pushCode"
            :can-push-to-branch="blobInfo.canCurrentUserPushToBranch"
            :empty-repo="project.repository.empty"
            :project-path="projectPath"
            :is-locked="Boolean(pathLockedByUser)"
            :can-lock="canLock"
            :show-fork-suggestion="showForkSuggestion"
            @fork="setForkTarget('ide')"
          />
        </template>
      </blob-header>
      <fork-suggestion
        v-if="forkTarget && showForkSuggestion"
        :fork-path="forkPath"
        @cancel="setForkTarget(null)"
      />
      <blob-content
        v-if="!blobViewer"
        class="js-syntax-highlight"
        :rich-viewer="legacyRichViewer"
        :blob="blobInfo"
        :content="legacySimpleViewer"
        :is-raw-content="true"
        :active-viewer="viewer"
        :hide-line-numbers="true"
        :loading="isLoadingLegacyViewer"
      />
      <component :is="blobViewer" v-else :blob="blobInfo" class="blob-viewer" />
    </div>
  </div>
</template>
