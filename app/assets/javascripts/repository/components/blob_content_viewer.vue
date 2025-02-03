<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { isLoggedIn, handleLocationHash } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { visitUrl, getLocationHash } from '~/lib/utils/url_utility';
import CodeIntelligence from '~/code_navigation/components/app.vue';
import LineHighlighter from '~/blob/line_highlighter';
import blobInfoQuery from 'shared_queries/repository/blob_info.query.graphql';
import highlightMixin from '~/repository/mixins/highlight_mixin';
import projectInfoQuery from '../queries/project_info.query.graphql';
import getRefMixin from '../mixins/get_ref';
import { getRefType } from '../utils/ref_type';
import {
  DEFAULT_BLOB_INFO,
  TEXT_FILE_TYPE,
  LFS_STORAGE,
  LEGACY_FILE_TYPES,
  EMPTY_FILE,
} from '../constants';
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
    CodeIntelligence,
    AiGenie: () => import('ee_component/ai/components/ai_genie.vue'),
  },
  mixins: [getRefMixin, highlightMixin, glFeatureFlagMixin()],
  inject: {
    originalBranch: {
      default: '',
    },
    explainCodeAvailable: { default: false },
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
      error() {
        this.displayError();
      },
      update({ project }) {
        this.pathLocks = project.pathLocks || DEFAULT_BLOB_INFO.pathLocks;
        this.userPermissions = project.userPermissions;
      },
    },
    project: {
      query: blobInfoQuery,
      variables() {
        const queryVariables = {
          projectPath: this.projectPath,
          filePath: [this.path],
          ref: this.currentRef,
          refType: getRefType(this.refType),
          shouldFetchRawText: true,
        };

        return queryVariables;
      },
      result({ data }) {
        const repository = data.project?.repository || {};
        this.blobInfo = repository.blobs?.nodes[0] || {};
        this.isEmptyRepository = repository.empty;
        this.projectId = data.project?.id;

        const usePlain = this.$route?.query?.plain === '1'; // When the 'plain' URL param is present, its value determines which viewer to render
        const urlHash = getLocationHash(); // If there is a code line hash in the URL we render with the simple viewer
        const useSimpleViewer = usePlain || urlHash?.startsWith('L') || !this.hasRichViewer;

        if (this.isUnsupportedLanguage(this.blobInfo.language) && this.isTooLarge) return;
        this.initHighlightWorker(this.blobInfo, this.isUsingLfs);
        this.switchViewer(useSimpleViewer ? SIMPLE_BLOB_VIEWER : RICH_BLOB_VIEWER); // By default, if present, use the rich viewer to render
      },
      error() {
        this.displayError();
      },
    },
  },
  provide() {
    return { blobHash: uniqueId() };
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
    refType: {
      type: String,
      required: false,
      default: null,
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
      currentUser: DEFAULT_BLOB_INFO.currentUser,
      useFallback: false,
      pathLocks: DEFAULT_BLOB_INFO.pathLocks,
      userPermissions: DEFAULT_BLOB_INFO.userPermissions,
      blobInfo: {},
      isEmptyRepository: false,
      projectId: null,
      showBlame: this.$route?.query?.blame === '1',
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
      return (
        this.isBinary ||
        (this.blobInfo.simpleViewer?.fileType !== TEXT_FILE_TYPE &&
          this.blobInfo.simpleViewer?.fileType !== EMPTY_FILE)
      );
    },
    currentRef() {
      return this.originalBranch || this.ref;
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
    isTooLarge() {
      if (this.isUnsupportedLanguage(this.blobInfo.language)) {
        // If the languages is not supported by HLJS then check if the backend indicated the file is too large
        const { tooLarge, renderError } = this.viewer || {};
        return tooLarge || renderError === 'collapsed';
      }

      return this.blobInfo.size >= this.$options.HLJS_MAX_SIZE;
    },
    blobViewer() {
      const { fileType } = this.viewer;
      const { isTooLarge } = this;
      return this.shouldLoadLegacyViewer ? null : loadViewer(fileType, this.isUsingLfs, isTooLarge);
    },
    shouldLoadLegacyViewer() {
      return LEGACY_FILE_TYPES.includes(this.blobInfo.fileType) || this.useFallback;
    },
    legacyViewerLoaded() {
      return (
        (this.activeViewerType === SIMPLE_BLOB_VIEWER && this.legacySimpleViewer) ||
        (this.activeViewerType === RICH_BLOB_VIEWER && this.legacyRichViewer)
      );
    },
    canLock() {
      const { pushCode, downloadCode } = this.userPermissions;
      const currentUsername = window.gon?.current_username;

      if (this.pathLockedByUser && this.pathLockedByUser.username !== currentUsername) {
        return false;
      }

      return pushCode && downloadCode;
    },
    pathLockedByUser() {
      const pathLock = this.pathLocks?.nodes.find((node) => node.path === this.path);

      return pathLock ? pathLock.user : null;
    },
    canFork() {
      const { createMergeRequestIn, forkProject } = this.userPermissions;

      return this.isLoggedIn && !this.isUsingLfs && createMergeRequestIn && forkProject;
    },
    showSingleFileEditorForkSuggestion() {
      const { canModifyBlob } = this.blobInfo;
      return this.canFork && !canModifyBlob;
    },
    showWebIdeForkSuggestion() {
      const { canModifyBlobWithWebIde } = this.blobInfo;

      return this.canFork && !canModifyBlobWithWebIde;
    },
    showForkSuggestion() {
      return this.showSingleFileEditorForkSuggestion || this.showWebIdeForkSuggestion;
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
    shouldRenderAiGenie() {
      return this.explainCodeAvailable && this.activeViewerType === 'simple' && !this.isTooLarge;
    },
    shouldHideViewerSwitcher() {
      return (
        this.isBinaryFileType ||
        this.isUsingLfs ||
        this.blobInfo.simpleViewer?.fileType === EMPTY_FILE
      );
    },
  },
  watch: {
    // Watch the URL 'plain' query value to know if the viewer needs changing.
    // This is the case when the user switches the viewer and then goes back through the history
    '$route.query.plain': {
      handler(plainValue) {
        const useSimpleViewer = plainValue === '1' || !this.hasRichViewer;
        this.switchViewer(useSimpleViewer ? SIMPLE_BLOB_VIEWER : RICH_BLOB_VIEWER);
      },
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

      const newUrl = new URL(this.blobInfo.webPath, window.location.origin);
      newUrl.searchParams.set('format', 'json');
      newUrl.searchParams.set('viewer', type);
      axios
        .get(newUrl.pathname + newUrl.search)
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
      createAlert({ message: __('An error occurred while loading the file. Please try again.') });
    },
    switchViewer(newViewer) {
      this.activeViewerType = newViewer || SIMPLE_BLOB_VIEWER;

      if (!this.blobViewer) {
        this.loadLegacyViewer();
      }
    },
    handleViewerChanged(newViewer) {
      this.switchViewer(newViewer);
      const plain = newViewer === SIMPLE_BLOB_VIEWER ? '1' : '0';
      if (this.$route?.query?.plain === plain) return;
      this.$router.push({ path: this.$route.path, query: { ...this.$route.query, plain } });
    },
    isIdeTarget(target) {
      return target === 'ide';
    },
    forkSuggestionForSelectedEditor(target) {
      return this.isIdeTarget(target)
        ? this.showWebIdeForkSuggestion
        : this.showSingleFileEditorForkSuggestion;
    },
    editBlob(target) {
      const { ideEditPath, editBlobPath } = this.blobInfo;
      const isIdeTarget = this.isIdeTarget(target);
      const showForkSuggestionForSelectedEditor = this.forkSuggestionForSelectedEditor(target);

      if (showForkSuggestionForSelectedEditor) {
        this.setForkTarget(target);
      } else {
        visitUrl(isIdeTarget ? ideEditPath : editBlobPath);
      }
    },
    setForkTarget(target) {
      this.forkTarget = target;
    },
    onCopy() {
      navigator.clipboard.writeText(this.blobInfo.rawTextBlob);
    },
    handleToggleBlame() {
      this.switchViewer(SIMPLE_BLOB_VIEWER);

      if (this.$route?.query?.plain === '0') {
        // If the user is not viewing plain code and clicks the blame button, we always want to show blame info
        // For instance, when viewing the rendered version of a Markdown file
        this.showBlame = true;
      } else {
        this.showBlame = !this.showBlame;
      }

      const blame = this.showBlame === true ? '1' : '0';
      if (this.$route?.query?.blame === blame) return;
      this.$router.push({ path: this.$route.path, query: { ...this.$route.query, blame } });
    },
  },
};
</script>

<template>
  <div class="gl-relative">
    <gl-loading-icon v-if="isLoading" size="sm" />
    <div v-if="blobInfo && !isLoading" id="fileHolder" class="file-holder">
      <blob-header
        is-blob-page
        :blob="blobInfo"
        :hide-viewer-switcher="shouldHideViewerSwitcher"
        :is-binary="isBinaryFileType"
        :active-viewer-type="viewer.type"
        :has-render-error="hasRenderError"
        :show-path="false"
        :override-copy="true"
        :show-fork-suggestion="showSingleFileEditorForkSuggestion"
        :show-web-ide-fork-suggestion="showWebIdeForkSuggestion"
        :show-blame-toggle="glFeatures.inlineBlame"
        :project-path="projectPath"
        :project-id="projectId"
        @viewer-changed="handleViewerChanged"
        @copy="onCopy"
        @edit="editBlob"
        @error="displayError"
        @blame="handleToggleBlame"
      >
        <template #actions>
          <blob-button-group
            v-if="isLoggedIn && !blobInfo.archived && !glFeatures.blobOverflowMenu"
            :path="path"
            :name="blobInfo.name"
            :replace-path="blobInfo.replacePath"
            :delete-path="blobInfo.webPath"
            :can-push-code="userPermissions.pushCode"
            :can-push-to-branch="blobInfo.canCurrentUserPushToBranch"
            :empty-repo="isEmptyRepository"
            :project-path="projectPath"
            :is-locked="Boolean(pathLockedByUser)"
            :can-lock="canLock"
            :show-fork-suggestion="showSingleFileEditorForkSuggestion"
            :is-using-lfs="isUsingLfs"
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
        :show-blame="showBlame && glFeatures.inlineBlame"
        :current-ref="currentRef"
        :loading="isLoadingLegacyViewer"
        :project-path="projectPath"
        :data-loading="isRenderingLegacyTextViewer"
      />
      <component
        :is="blobViewer"
        v-else
        :blob="blobInfo"
        :chunks="chunks"
        :show-blame="showBlame && glFeatures.inlineBlame"
        :project-path="projectPath"
        :current-ref="currentRef"
        class="blob-viewer"
        @error="onError"
      />
      <code-intelligence
        v-if="blobViewer || legacyViewerLoaded"
        :code-navigation-path="blobInfo.codeNavigationPath"
        :blob-path="blobInfo.path"
        :path-prefix="blobInfo.projectBlobPathRoot"
        :wrap-text-nodes="true"
      />
    </div>
    <ai-genie
      v-if="shouldRenderAiGenie"
      container-selector=".file-content"
      :file-path="path"
      class="gl-ml-7"
    />
  </div>
</template>
