<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { __ } from '~/locale';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import {
  keysFor,
  TOGGLE_FILE_TREE_BROWSER_VISIBILITY,
  START_SEARCH_PROJECT_FILE,
} from '~/behaviors/shortcuts/keybindings';
import { sanitize } from '~/lib/dompurify';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_BUTTON_CLICK, REF_SELECTOR_CLICK } from '~/tracking/constants';
import { visitUrl, joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import FileTreeBrowserToggle from '~/repository/file_tree_browser/components/file_tree_browser_toggle.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import RepositoryOverflowMenu from '~/repository/components/header_area/repository_overflow_menu.vue';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import SourceCodeDownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';
import CloneCodeDropdown from '~/vue_shared/components/code_dropdown/clone_code_dropdown.vue';
import AddToTree from '~/repository/components/header_area/add_to_tree.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { useViewport } from '~/pinia/global_stores/viewport';
import { Mousetrap } from '~/lib/mousetrap';
import {
  EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
  EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
} from '~/repository/constants';

export default {
  name: 'HeaderArea',
  i18n: {
    compare: __('Compare'),
    findFile: __('Find file'),
  },
  components: {
    GlButton,
    FileIcon,
    RefSelector,
    Breadcrumbs,
    RepositoryOverflowMenu,
    BlobControls,
    CodeDropdown,
    CompactCodeDropdown: () =>
      import('ee_else_ce/repository/components/code_dropdown/compact_code_dropdown.vue'),
    SourceCodeDownloadDropdown,
    CloneCodeDropdown,
    AddToTree,
    WebIdeLink: () => import('ee_else_ce/vue_shared/components/web_ide_link.vue'),
    LockDirectoryButton: () =>
      import('ee_component/repository/components/lock_directory_button.vue'),
    HeaderLockIcon: () =>
      import('ee_component/repository/components/header_area/header_lock_icon.vue'),
    FileTreeBrowserToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin(), InternalEvents.mixin()],
  inject: [
    'canCollaborate',
    'canEditTree',
    'canPushCode',
    'canPushToBranch',
    'originalBranch',
    'selectedBranch',
    'newBranchPath',
    'newTagPath',
    'newBlobPath',
    'forkNewBlobPath',
    'forkNewDirectoryPath',
    'forkUploadBlobPath',
    'uploadPath',
    'newDirPath',
    'projectRootPath',
    'comparePath',
    'isReadmeView',
    'isFork',
    'needsToFork',
    'isGitpodEnabledForUser',
    'isBlob',
    'showEditButton',
    'showWebIdeButton',
    'isGitpodEnabledForInstance',
    'showPipelineEditorUrl',
    'webIdeUrl',
    'editUrl',
    'pipelineEditorUrl',
    'gitpodUrl',
    'userPreferencesGitpodPath',
    'userProfileEnableGitpodPath',
    'httpUrl',
    'xcodeUrl',
    'sshUrl',
    'kerberosUrl',
    'downloadLinks',
    'downloadArtifacts',
    'isBinary',
    'rootRef',
  ],
  provide() {
    return {
      currentRef: this.currentRef,
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    refType: {
      type: String,
      required: false,
      default: null,
    },
    currentRef: {
      type: String,
      required: false,
      default: null,
    },
    projectId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      directoryLocked: false,
      fileLocked: false,
      lockAuthor: undefined,
    };
  },
  computed: {
    ...mapState(useFileTreeBrowserVisibility, ['fileTreeBrowserIsVisible']),
    ...mapState(useViewport, ['isCompactSize']),
    isTreeView() {
      return this.$route.name !== 'blobPathDecoded';
    },
    isProjectOverview() {
      return this.$route.name === 'projectRoot';
    },
    isRoot() {
      return !this.currentPath || this.currentPath === '/';
    },
    directoryName() {
      return this.currentPath
        ? this.currentPath.split('/').pop()
        : this.projectPath.split('/').pop();
    },
    fileIconName() {
      return this.isTreeView ? 'folder-open' : this.directoryName;
    },
    isLocked() {
      return this.isTreeView ? this.directoryLocked : this.fileLocked;
    },
    getRefType() {
      return this.$route.query.ref_type;
    },
    currentPath() {
      return this.$route.params.path;
    },
    refSelectorQueryParams() {
      return {
        sort: 'updated_desc',
      };
    },
    refSelectorValue() {
      return this.refType ? joinPaths('refs', this.refType, this.currentRef) : this.currentRef;
    },
    webIDEUrl() {
      return this.isBlob
        ? this.webIdeUrl
        : webIDEUrl(
            joinPaths(
              '/',
              this.projectPath,
              'edit',
              this.currentRef,
              '-',
              this.$route?.params.path || '',
              '/',
            ),
          );
    },
    projectIdAsNumber() {
      return getIdFromGraphQLId(this.projectId);
    },
    findFileTooltip() {
      const { description } = START_SEARCH_PROJECT_FILE;
      const key = this.findFileShortcutKey;
      return shouldDisableShortcuts()
        ? null
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    findFileShortcutKey() {
      return keysFor(START_SEARCH_PROJECT_FILE)[0];
    },
    showCompactCodeDropdown() {
      return this.glFeatures.directoryCodeDropdownUpdates;
    },
    showBlobControls() {
      return this.$route.params.path && this.$route.name === 'blobPathDecoded';
    },
    showFileTreeBrowserToggle() {
      return (
        this.glFeatures.repositoryFileTreeBrowser &&
        !this.isProjectOverview &&
        !this.fileTreeBrowserIsVisible &&
        !this.isCompactSize
      );
    },
    toggleFileBrowserShortcutKey() {
      return this.shortcutsEnabled ? keysFor(TOGGLE_FILE_TREE_BROWSER_VISIBILITY)[0] : null;
    },
    shortcutsEnabled() {
      return !shouldDisableShortcuts();
    },
  },
  mounted() {
    if (this.glFeatures.repositoryFileTreeBrowser) {
      this.initializeFileTreeBrowser();
      this.bindShortcuts();
    }
  },
  beforeDestroy() {
    this.unbindShortcuts();
  },
  methods: {
    ...mapActions(useFileTreeBrowserVisibility, [
      'initializeFileTreeBrowser',
      'handleFileTreeBrowserToggleClick',
    ]),
    onShortcutToggle() {
      this.handleFileTreeBrowserToggleClick();

      this.trackEvent(
        this.fileTreeBrowserIsVisible
          ? EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE
          : EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
        {
          label: 'shortcut',
        },
      );
    },
    bindShortcuts() {
      if (this.shortcutsEnabled) {
        Mousetrap.bind(keysFor(TOGGLE_FILE_TREE_BROWSER_VISIBILITY), this.onShortcutToggle);
      }
    },
    unbindShortcuts() {
      if (this.shortcutsEnabled) {
        Mousetrap.unbind(keysFor(TOGGLE_FILE_TREE_BROWSER_VISIBILITY));
      }
    },
    onInput(selectedRef) {
      this.trackEvent(REF_SELECTOR_CLICK);
      visitUrl(generateRefDestinationPath(this.projectRootPath, this.originalBranch, selectedRef));
    },
    handleFindFile() {
      this.trackEvent(FIND_FILE_BUTTON_CLICK);
      Shortcuts.focusSearchFile();
    },
    onLockedDirectory({ isLocked, lockAuthor }) {
      this.directoryLocked = isLocked;
      this.lockAuthor = lockAuthor;
    },
    onLockedFile({ isLocked, lockAuthor }) {
      this.fileLocked = isLocked;
      this.lockAuthor = lockAuthor;
    },
  },
};
</script>

<template>
  <section
    class="gl-items-center gl-justify-between"
    :class="{
      [glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-flex' : '@sm/panel:gl-flex']:
        isProjectOverview,
    }"
  >
    <div class="tree-ref-container !gl-mb-3 gl-flex gl-flex-wrap gl-gap-3 @md/panel:!gl-mb-0">
      <file-tree-browser-toggle
        v-if="showFileTreeBrowserToggle"
        ref="toggle"
        :aria-keyshortcuts="toggleFileBrowserShortcutKey"
        :aria-label="__('Toggle file tree browser visibility')"
      />
      <ref-selector
        v-if="!isReadmeView"
        class="tree-ref-holder gl-max-w-26"
        data-testid="ref-dropdown-container"
        :project-id="projectId"
        :value="refSelectorValue"
        :default-branch="rootRef"
        use-symbolic-ref-names
        :query-params="refSelectorQueryParams"
        @input="onInput"
      />
      <breadcrumbs
        v-if="!isReadmeView"
        class="js-repo-breadcrumbs"
        :current-path="currentPath"
        :ref-type="getRefType"
        :can-collaborate="canCollaborate"
        :can-edit-tree="canEditTree"
        :can-push-code="canPushCode"
        :can-push-to-branch="canPushToBranch"
        :original-branch="originalBranch"
        :selected-branch="selectedBranch"
        :new-branch-path="newBranchPath"
        :new-tag-path="newTagPath"
        :new-blob-path="newBlobPath"
        :fork-new-blob-path="forkNewBlobPath"
        :fork-new-directory-path="forkNewDirectoryPath"
        :fork-upload-blob-path="forkUploadBlobPath"
        :upload-path="uploadPath"
        :new-dir-path="newDirPath"
      />
    </div>

    <div
      :class="[
        'gl-flex gl-flex-col gl-items-stretch gl-justify-end',
        glFeatures.repositoryFileTreeBrowser
          ? '@md/panel:gl-flex-row @md/panel:gl-items-center @md/panel:gl-gap-5'
          : '@sm/panel:gl-flex-row @sm/panel:gl-items-center @sm/panel:gl-gap-5',
        { 'gl-my-5': !isProjectOverview },
      ]"
    >
      <h1
        v-if="!isReadmeView && !isProjectOverview"
        :class="[
          'gl-mt-0 gl-inline-flex gl-flex-1 gl-items-center gl-gap-3 gl-break-words gl-text-size-h1',
          glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-my-0' : '@sm/panel:gl-my-0',
        ]"
        data-testid="repository-heading"
      >
        <file-icon
          :file-name="fileIconName"
          :folder="isTreeView"
          opened
          aria-hidden="true"
          class="gl-inline-flex"
          :class="{ 'gl-text-subtle': isTreeView }"
        />{{ directoryName }}
        <header-lock-icon
          v-if="!isRoot"
          :is-tree-view="isTreeView"
          :is-locked="isLocked"
          :lock-author="lockAuthor"
        />
      </h1>

      <!-- Tree controls -->
      <div
        v-if="!showBlobControls"
        :class="[
          'tree-controls gl-mb-3 gl-flex gl-flex-wrap gl-gap-3',
          glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-mb-0' : '@sm/panel:gl-mb-0',
        ]"
        data-testid="tree-controls-container"
      >
        <add-to-tree
          v-if="!isReadmeView && showCompactCodeDropdown"
          :class="[
            'gl-hidden',
            glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-block' : '@sm/panel:gl-block',
          ]"
          :current-path="currentPath"
          :can-collaborate="canCollaborate"
          :can-edit-tree="canEditTree"
          :can-push-code="canPushCode"
          :can-push-to-branch="canPushToBranch"
          :original-branch="originalBranch"
          :selected-branch="selectedBranch"
          :new-branch-path="newBranchPath"
          :new-tag-path="newTagPath"
          :new-blob-path="newBlobPath"
          :fork-new-blob-path="forkNewBlobPath"
          :fork-new-directory-path="forkNewDirectoryPath"
          :fork-upload-blob-path="forkUploadBlobPath"
          :upload-path="uploadPath"
          :new-dir-path="newDirPath"
        />
        <!-- EE lock directory -->
        <lock-directory-button
          v-if="!isRoot"
          :project-path="projectPath"
          :path="currentPath"
          @lockedDirectory="onLockedDirectory"
        />
        <gl-button
          v-gl-tooltip.html="findFileTooltip"
          :aria-keyshortcuts="findFileShortcutKey"
          data-testid="tree-find-file-control"
          :class="[
            'gl-w-full',
            glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-w-auto' : '@sm/panel:gl-w-auto',
          ]"
          @click="handleFindFile"
        >
          {{ $options.i18n.findFile }}
        </gl-button>
        <!-- web ide -->
        <web-ide-link
          :class="[
            'gl-w-full @sm/panel:!gl-ml-0',
            glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-w-auto' : '@sm/panel:gl-w-auto',
          ]"
          data-testid="js-tree-web-ide-link"
          :project-id="projectIdAsNumber"
          :project-path="projectPath"
          :is-fork="isFork"
          :needs-to-fork="needsToFork"
          :is-gitpod-enabled-for-user="isGitpodEnabledForUser"
          :is-blob="isBlob"
          :show-edit-button="showEditButton"
          :show-web-ide-button="showWebIdeButton"
          :is-gitpod-enabled-for-instance="isGitpodEnabledForInstance"
          :show-pipeline-editor-url="showPipelineEditorUrl"
          :web-ide-url="webIDEUrl"
          :edit-url="editUrl"
          :pipeline-editor-url="pipelineEditorUrl"
          :gitpod-url="gitpodUrl"
          :user-preferences-gitpod-path="userPreferencesGitpodPath"
          :user-profile-enable-gitpod-path="userProfileEnableGitpodPath"
          :git-ref="currentRef"
          disable-fork-modal
          v-on="$listeners"
        />
        <!-- code + mobile panel -->
        <div
          :class="[
            'project-code-holder gl-w-full',
            glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-w-auto' : '@sm/panel:gl-w-auto',
          ]"
        >
          <div v-if="showCompactCodeDropdown" class="gl-flex gl-justify-end gl-gap-3">
            <add-to-tree
              v-if="!isReadmeView"
              :class="
                glFeatures.repositoryFileTreeBrowser ? '@md/panel:gl-hidden' : '@sm/panel:gl-hidden'
              "
              :current-path="currentPath"
              :can-collaborate="canCollaborate"
              :can-edit-tree="canEditTree"
              :can-push-code="canPushCode"
              :can-push-to-branch="canPushToBranch"
              :original-branch="originalBranch"
              :selected-branch="selectedBranch"
              :new-branch-path="newBranchPath"
              :new-tag-path="newTagPath"
              :new-blob-path="newBlobPath"
              :fork-new-blob-path="forkNewBlobPath"
              :fork-new-directory-path="forkNewDirectoryPath"
              :fork-upload-blob-path="forkUploadBlobPath"
              :upload-path="uploadPath"
              :new-dir-path="newDirPath"
            />
            <compact-code-dropdown
              class="gl-ml-auto"
              :ssh-url="sshUrl"
              :http-url="httpUrl"
              :kerberos-url="kerberosUrl"
              :xcode-url="xcodeUrl"
              :web-ide-url="webIDEUrl"
              :gitpod-url="gitpodUrl"
              :current-path="currentPath"
              :directory-download-links="downloadLinks"
              :project-id="projectId"
              :project-path="projectPath"
              :git-ref="currentRef"
              :show-web-ide-button="showWebIdeButton"
              :is-gitpod-enabled-for-instance="isGitpodEnabledForInstance"
              :is-gitpod-enabled-for-user="isGitpodEnabledForUser"
            />
            <repository-overflow-menu
              :full-path="projectPath"
              :path="currentPath"
              :current-ref="currentRef"
            />
          </div>
          <template v-else-if="!isReadmeView">
            <code-dropdown
              :class="[
                'git-clone-holder js-git-clone-holder gl-hidden',
                glFeatures.repositoryFileTreeBrowser
                  ? '@md/panel:gl-inline-block'
                  : '@sm/panel:gl-inline-block',
              ]"
              :ssh-url="sshUrl"
              :http-url="httpUrl"
              :kerberos-url="kerberosUrl"
              :xcode-url="xcodeUrl"
              :current-path="currentPath"
              :directory-download-links="downloadLinks"
            />
            <div
              :class="[
                'gl-flex gl-w-full gl-gap-3',
                glFeatures.repositoryFileTreeBrowser
                  ? '@md/panel:gl-inline-block @md/panel:gl-w-auto'
                  : '@sm/panel:gl-inline-block @sm/panel:gl-w-auto',
              ]"
            >
              <div
                :class="[
                  'gl-flex gl-w-full gl-items-stretch gl-gap-3',
                  glFeatures.repositoryFileTreeBrowser
                    ? '@md/panel:gl-hidden'
                    : '@sm/panel:gl-hidden',
                ]"
              >
                <source-code-download-dropdown
                  :download-links="downloadLinks"
                  :download-artifacts="downloadArtifacts"
                />
                <clone-code-dropdown
                  class="mobile-git-clone js-git-clone-holder !gl-w-full"
                  :ssh-url="sshUrl"
                  :http-url="httpUrl"
                  :kerberos-url="kerberosUrl"
                />
              </div>
              <repository-overflow-menu
                :full-path="projectPath"
                :path="currentPath"
                :current-ref="currentRef"
              />
            </div>
          </template>
        </div>
      </div>

      <!-- Blob controls -->
      <blob-controls
        v-if="showBlobControls"
        :project-path="projectPath"
        :project-id-as-number="projectIdAsNumber"
        :ref-type="getRefType"
        :is-binary="isBinary"
        @lockedFile="onLockedFile"
      />
    </div>
  </section>
</template>
