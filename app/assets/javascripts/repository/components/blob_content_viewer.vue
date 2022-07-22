<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { isLoggedIn, handleLocationHash } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';
import CodeIntelligence from '~/code_navigation/components/app.vue';
import LineHighlighter from '~/blob/line_highlighter';
import getRefMixin from '../mixins/get_ref';
import blobInfoQuery from '../queries/blob_info.query.graphql';
import userInfoQuery from '../queries/user_info.query.graphql';
import applicationInfoQuery from '../queries/application_info.query.graphql';
import { DEFAULT_BLOB_INFO, TEXT_FILE_TYPE, LFS_STORAGE, LEGACY_FILE_TYPES } from '../constants';
import BlobButtonGroup from './blob_button_group.vue';
import ForkSuggestion from './fork_suggestion.vue';
import { loadViewer } from './blob_viewers';

export default {
  components: {
    BlobHeader,
    BlobButtonGroup,
    BlobContent,
    GlLoadingIcon,
    GlButton,
    ForkSuggestion,
    WebIdeLink,
    CodeIntelligence,
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
  inject: {
    originalBranch: {
      default: '',
    },
  },
  apollo: {
    gitpodEnabled: {
      query: applicationInfoQuery,
      error() {
        this.displayError();
      },
    },
    currentUser: {
      query: userInfoQuery,
      error() {
        this.displayError();
      },
    },
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
      isRenderingLegacyTextViewer: false,
      activeViewerType: SIMPLE_BLOB_VIEWER,
      project: DEFAULT_BLOB_INFO.project,
      gitpodEnabled: DEFAULT_BLOB_INFO.gitpodEnabled,
      currentUser: DEFAULT_BLOB_INFO.currentUser,
      useFallback: false,
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
      const isTextFile = this.viewer.fileType === TEXT_FILE_TYPE && !this.glFeatures.highlightJs;
      return isTextFile || LEGACY_FILE_TYPES.includes(this.blobInfo.fileType) || this.useFallback;
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
      const forkPaths = {
        ide: this.blobInfo.ideForkAndEditPath,
        simple: this.blobInfo.forkAndEditPath,
        view: this.blobInfo.forkAndViewPath,
      };

      return forkPaths[this.forkTarget];
    },
    isUsingLfs() {
      return this.blobInfo.storedExternally && this.blobInfo.externalStorage === LFS_STORAGE;
    },
  },
  methods: {
    onError() {
      this.useFallback = true;
      this.loadLegacyViewer();
    },
    loadLegacyViewer() {
      if (this.legacyViewerLoaded) {
        return;
      }

      const type = this.activeViewerType;

      this.isLoadingLegacyViewer = true;
      axios
        .get(`${this.blobInfo.webPath}?format=json&viewer=${type}`)
        .then(async ({ data: { html, binary } }) => {
          this.isRenderingLegacyTextViewer = true;

          if (type === SIMPLE_BLOB_VIEWER) {
            this.legacySimpleViewer = html;
          } else {
            this.legacyRichViewer = html;
          }

          this.isBinary = binary;
          this.isLoadingLegacyViewer = false;

          window.requestIdleCallback(() => {
            this.isRenderingLegacyTextViewer = false;

            if (type === SIMPLE_BLOB_VIEWER) {
              new LineHighlighter(); // eslint-disable-line no-new
            }
          });

          await this.$nextTick();
          handleLocationHash(); // Ensures that we scroll to the hash when async content is loaded
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
    onCopy() {
      navigator.clipboard.writeText(this.blobInfo.rawTextBlob);
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
        :override-copy="glFeatures.highlightJs"
        @viewer-changed="switchViewer"
        @copy="onCopy"
      >
        <template #actions>
          <web-ide-link
            v-if="!blobInfo.archived"
            :show-edit-button="!isBinaryFileType"
            class="gl-mr-3"
            :edit-url="blobInfo.editBlobPath"
            :web-ide-url="blobInfo.ideEditPath"
            :needs-to-fork="showForkSuggestion"
            :show-pipeline-editor-button="Boolean(blobInfo.pipelineEditorPath)"
            :pipeline-editor-url="blobInfo.pipelineEditorPath"
            :gitpod-url="blobInfo.gitpodBlobUrl"
            :show-gitpod-button="gitpodEnabled"
            :gitpod-enabled="currentUser && currentUser.gitpodEnabled"
            :user-preferences-gitpod-path="currentUser && currentUser.preferencesGitpodPath"
            :user-profile-enable-gitpod-path="currentUser && currentUser.profileEnableGitpodPath"
            is-blob
            disable-fork-modal
            @edit="editBlob"
          />

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
            @fork="setForkTarget('view')"
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
        :data-loading="isRenderingLegacyTextViewer"
      />
      <component :is="blobViewer" v-else :blob="blobInfo" class="blob-viewer" @error="onError" />
      <code-intelligence
        v-if="blobViewer || legacyViewerLoaded"
        :code-navigation-path="blobInfo.codeNavigationPath"
        :blob-path="blobInfo.path"
        :path-prefix="blobInfo.projectBlobPathRoot"
        :wrap-text-nodes="glFeatures.highlightJs"
      />
    </div>
  </div>
</template>
