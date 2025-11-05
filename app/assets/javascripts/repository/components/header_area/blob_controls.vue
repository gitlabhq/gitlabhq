<script>
import { GlButton, GlTooltipDirective, GlLoadingIcon } from '@gitlab/ui';
import { computed } from 'vue';
import { __ } from '~/locale';
import { logError } from '~/lib/logger';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import getRefMixin from '~/repository/mixins/get_ref';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import initSourcegraph from '~/sourcegraph';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { keysFor, START_SEARCH_PROJECT_FILE } from '~/behaviors/shortcuts/keybindings';
import { sanitize } from '~/lib/dompurify';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_BUTTON_CLICK, BLAME_BUTTON_CLICK } from '~/tracking/constants';
import {
  showSingleFileEditorForkSuggestion,
  showWebIdeForkSuggestion,
  isIdeTarget,
  forkSuggestionForSelectedEditor,
} from '~/repository/utils/fork_suggestion_utils';
import { showBlameButton, isUsingLfs } from '~/repository/utils/storage_info_utils';
import blobControlsQuery from '~/repository/queries/blob_controls.query.graphql';
import userGitpodInfo from '~/repository/queries/user_gitpod_info.query.graphql';
import applicationInfoQuery from '~/repository/queries/application_info.query.graphql';
import { getRefType } from '~/repository/utils/ref_type';
import OpenMrBadge from '~/badges/components/open_mr_badge/open_mr_badge.vue';
import BlobOverflowMenu from 'ee_else_ce/repository/components/header_area/blob_overflow_menu.vue';
import ForkSuggestionModal from '~/repository/components/header_area/fork_suggestion_modal.vue';
import { TEXT_FILE_TYPE, EMPTY_FILE, DEFAULT_BLOB_INFO } from '../../constants';

export default {
  i18n: {
    findFile: __('Find file'),
    blame: __('Blame'),
    errorMessage: __('An error occurred while loading file controls. Refresh the page.'),
    archivedProjectTooltip: __('You cannot edit files in archived projects'),
    lfsFileTooltip: __('You cannot edit files stored in LFS'),
  },
  buttonClassList: '@sm/panel:gl-w-auto gl-w-full @sm/panel:gl-mt-0 gl-mt-3',
  components: {
    OpenMrBadge,
    GlButton,
    GlLoadingIcon,
    BlobOverflowMenu,
    ForkSuggestionModal,
    WebIdeLink: () => import('ee_else_ce/vue_shared/components/web_ide_link.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [getRefMixin, glFeatureFlagMixin(), InternalEvents.mixin()],
  apollo: {
    project: {
      query: blobControlsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.filePath,
          ref: this.ref,
          refType: getRefType(this.refType),
        };
      },
      skip() {
        return !this.filePath;
      },
      error(error) {
        this.hasProjectQueryErrors = true;
        createAlert({ message: this.$options.i18n.errorMessage });
        logError(
          `Failed to fetch blob controls. See exception details for more information.`,
          error,
        );
        Sentry.captureException(error);
      },
    },
    currentUser: {
      query: userGitpodInfo,
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage });
        logError(
          `Failed to fetch current user. See exception details for more information.`,
          error,
        );
        Sentry.captureException(error);
      },
    },
    gitpodEnabled: {
      query: applicationInfoQuery,
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage });
        logError(
          `Failed to fetch application info. See exception details for more information.`,
          error,
        );
        Sentry.captureException(error);
      },
    },
  },
  inject: ['currentRef'],
  provide() {
    return {
      blobInfo: computed(() => this.blobInfo ?? DEFAULT_BLOB_INFO.repository.blobs.nodes[0]),
      currentRef: computed(() => this.currentRef ?? this.blobInfo.ref),
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    projectIdAsNumber: {
      type: Number,
      required: true,
    },
    refType: {
      type: String,
      required: false,
      default: null,
    },
    isBinary: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      project: {},
      currentUser: {},
      gitpodEnabled: false,
      isForkSuggestionModalVisible: false,
      hasProjectQueryErrors: false,
    };
  },
  computed: {
    controlsCollapseClass() {
      const breakpoint = this.glFeatures.repositoryFileTreeBrowser
        ? '@md/panel:gl-inline-flex'
        : '@sm/panel:gl-inline-flex';
      return `gl-hidden ${breakpoint}`;
    },
    isLoadingRepositoryBlob() {
      return this.$apollo.queries.project.loading;
    },
    filePath() {
      return this.$route.params.path;
    },
    blobInfo() {
      return this.project?.repository?.blobs?.nodes[0] || {};
    },
    repository() {
      return this.project?.repository || DEFAULT_BLOB_INFO.repository;
    },
    userPermissions() {
      return this.project?.userPermissions || DEFAULT_BLOB_INFO.userPermissions;
    },
    showBlameButton() {
      return showBlameButton(this.blobInfo);
    },
    isUsingLfs() {
      return isUsingLfs(this.blobInfo);
    },
    isBinaryFileType() {
      return (
        this.isBinary ||
        (this.blobInfo.simpleViewer?.fileType !== TEXT_FILE_TYPE &&
          this.blobInfo.simpleViewer?.fileType !== EMPTY_FILE)
      );
    },
    shortcuts() {
      return {
        findFile: keysFor(START_SEARCH_PROJECT_FILE)[0],
      };
    },
    findFileTooltip() {
      if (shouldDisableShortcuts()) return null;

      const { description } = START_SEARCH_PROJECT_FILE;
      const shortcutKey = this.shortcuts.findFile;

      return this.formatTooltipWithShortcut(description, shortcutKey);
    },
    shouldShowSingleFileEditorForkSuggestion() {
      return showSingleFileEditorForkSuggestion(
        this.userPermissions,
        this.isUsingLfs,
        this.blobInfo.canModifyBlob,
      );
    },
    shouldShowWebIdeForkSuggestion() {
      return showWebIdeForkSuggestion(
        this.userPermissions,
        this.isUsingLfs,
        this.blobInfo.canModifyBlobWithWebIde,
      );
    },
    isWebIdeDisabled() {
      return Object.values(this.webIdeDisabledReasons).some(
        ({ condition }) => condition() === true,
      );
    },
    webIdeDisabledTooltip() {
      const disabledReason = Object.values(this.webIdeDisabledReasons).find((reason) =>
        reason.condition(),
      );

      return disabledReason?.message ?? '';
    },
    webIdeDisabledReasons() {
      return {
        queryErrors: {
          condition: () => this.hasProjectQueryErrors,
          message: this.$options.i18n.errorMessage,
        },
        archived: {
          condition: () => this.blobInfo.archived,
          message: this.$options.i18n.archivedProjectTooltip,
        },
        lfs: {
          condition: () => this.isUsingLfs,
          message: this.$options.i18n.lfsFileTooltip,
        },
      };
    },
  },
  watch: {
    blobInfo() {
      initSourcegraph();
    },
  },
  methods: {
    formatTooltipWithShortcut(description, key) {
      return sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    handleFindFile() {
      this.trackEvent(FIND_FILE_BUTTON_CLICK);
      Shortcuts.focusSearchFile();
    },
    handleBlameClick() {
      this.trackEvent(BLAME_BUTTON_CLICK);
    },
    onCopy() {
      // eslint-disable-next-line no-restricted-properties
      navigator.clipboard.writeText(this.blobInfo.rawTextBlob);
    },
    onShowForkSuggestion() {
      this.isForkSuggestionModalVisible = true;
    },
    onEdit(target) {
      const { ideEditPath, editBlobPath } = this.blobInfo;
      const showForkSuggestionForSelectedEditor = forkSuggestionForSelectedEditor(
        target,
        this.shouldShowWebIdeForkSuggestion,
        this.shouldShowSingleFileEditorForkSuggestion,
      );

      if (showForkSuggestionForSelectedEditor) {
        this.isForkSuggestionModalVisible = true;
      } else {
        visitUrl(isIdeTarget(target) ? ideEditPath : editBlobPath);
      }
    },
    onLockedFile(event) {
      this.$emit('lockedFile', event);
    },
  },
};
</script>
<template>
  <div
    class="gl-flex gl-flex-wrap gl-items-center gl-gap-3 gl-self-end"
    data-testid="blob-controls"
  >
    <open-mr-badge :project-path="projectPath" :blob-path="filePath" :current-ref="currentRef" />
    <gl-button
      v-gl-tooltip.html="findFileTooltip"
      :title="findFileTooltip"
      :aria-keyshortcuts="shortcuts.findFile"
      data-testid="find"
      :class="[$options.buttonClassList, controlsCollapseClass]"
      @click="handleFindFile"
    >
      {{ $options.i18n.findFile }}
    </gl-button>
    <gl-button
      v-if="showBlameButton"
      data-testid="blame"
      :href="blobInfo.blamePath"
      :class="[$options.buttonClassList, controlsCollapseClass]"
      class="js-blob-blame-link"
      @click="handleBlameClick"
    >
      {{ $options.i18n.blame }}
    </gl-button>

    <web-ide-link
      class="!gl-m-0"
      :show-edit-button="!isBinaryFileType"
      :edit-url="blobInfo.editBlobPath"
      :web-ide-url="blobInfo.ideEditPath"
      :needs-to-fork="shouldShowSingleFileEditorForkSuggestion"
      :needs-to-fork-with-web-ide="shouldShowWebIdeForkSuggestion"
      :show-pipeline-editor-button="Boolean(blobInfo.pipelineEditorPath)"
      :pipeline-editor-url="blobInfo.pipelineEditorPath"
      :gitpod-url="blobInfo.gitpodBlobUrl"
      :is-gitpod-enabled-for-instance="gitpodEnabled"
      :is-gitpod-enabled-for-user="currentUser && currentUser.gitpodEnabled"
      :project-path="projectPath"
      :project-id="projectIdAsNumber"
      :user-preferences-gitpod-path="currentUser && currentUser.preferencesGitpodPath"
      :user-profile-enable-gitpod-path="currentUser && currentUser.profileEnableGitpodPath"
      is-blob
      disable-fork-modal
      :disabled="isWebIdeDisabled"
      :custom-tooltip-text="webIdeDisabledTooltip"
      @edit="onEdit"
    />
    <fork-suggestion-modal
      v-if="!isLoadingRepositoryBlob && !hasProjectQueryErrors"
      :visible="isForkSuggestionModalVisible"
      :fork-path="blobInfo.forkAndViewPath"
      @hide="isForkSuggestionModalVisible = false"
    />

    <gl-loading-icon
      v-if="isLoadingRepositoryBlob"
      :label="__('Loading file actions')"
      class="gl-p-3"
      size="sm"
      color="dark"
      variant="spinner"
      :inline="false"
    />
    <blob-overflow-menu
      v-if="!isLoadingRepositoryBlob && !hasProjectQueryErrors"
      :project-path="projectPath"
      :is-binary-file-type="isBinaryFileType"
      :override-copy="true"
      :is-empty-repository="repository.empty"
      :is-using-lfs="isUsingLfs"
      @copy="onCopy"
      @showForkSuggestion="onShowForkSuggestion"
      @lockedFile="onLockedFile"
    />
  </div>
</template>
