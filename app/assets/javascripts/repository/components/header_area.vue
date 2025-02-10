<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { keysFor, START_SEARCH_PROJECT_FILE } from '~/behaviors/shortcuts/keybindings';
import { sanitize } from '~/lib/dompurify';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_BUTTON_CLICK, REF_SELECTOR_CLICK } from '~/tracking/constants';
import { visitUrl, joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import RepositoryOverflowMenu from '~/repository/components/header_area/repository_overflow_menu.vue';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import CompactCodeDropdown from '~/repository/components/code_dropdown/compact_code_dropdown.vue';
import SourceCodeDownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';
import CloneCodeDropdown from '~/vue_shared/components/code_dropdown/clone_code_dropdown.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

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
    CompactCodeDropdown,
    SourceCodeDownloadDropdown,
    CloneCodeDropdown,
    WebIdeLink: () => import('ee_else_ce/vue_shared/components/web_ide_link.vue'),
    LockDirectoryButton: () =>
      import('ee_component/repository/components/lock_directory_button.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
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
    'gitpodEnabled',
    'isBlob',
    'showEditButton',
    'showWebIdeButton',
    'showGitpodButton',
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
  ],
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
  computed: {
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
  },
  methods: {
    onInput(selectedRef) {
      InternalEvents.trackEvent(REF_SELECTOR_CLICK);
      visitUrl(generateRefDestinationPath(this.projectRootPath, this.originalBranch, selectedRef));
    },
    handleFindFile() {
      InternalEvents.trackEvent(FIND_FILE_BUTTON_CLICK);
      Shortcuts.focusSearchFile();
    },
  },
};
</script>

<template>
  <section :class="{ 'gl-items-center gl-justify-between sm:gl-flex': isProjectOverview }">
    <div class="tree-ref-container mb-2 mb-md-0 gl-flex gl-flex-wrap gl-gap-5">
      <ref-selector
        v-if="!isReadmeView"
        class="tree-ref-holder gl-max-w-26"
        data-testid="ref-dropdown-container"
        :project-id="projectId"
        :value="refSelectorValue"
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
      class="gl-flex gl-flex-col gl-items-stretch gl-justify-end sm:gl-flex-row sm:gl-items-center sm:gl-gap-5"
      :class="{ 'gl-my-5': !isProjectOverview }"
    >
      <h1
        v-if="!isReadmeView && !isProjectOverview"
        class="gl-mt-0 gl-flex-1 gl-break-words gl-text-size-h1 sm:gl-my-0"
        data-testid="repository-heading"
      >
        <file-icon
          :file-name="fileIconName"
          :folder="isTreeView"
          opened
          aria-hidden="true"
          class="gl-mr-3 gl-inline-flex"
          :class="{ 'gl-text-gray-700': isTreeView }"
        />{{ directoryName }}
      </h1>

      <!-- Tree controls -->
      <div v-if="isTreeView" class="tree-controls gl-mb-3 gl-flex gl-flex-wrap gl-gap-3 sm:gl-mb-0">
        <!-- EE: = render_if_exists 'projects/tree/lock_link' -->
        <lock-directory-button v-if="!isRoot" :project-path="projectPath" :path="currentPath" />
        <gl-button
          v-gl-tooltip.html="findFileTooltip"
          :aria-keyshortcuts="findFileShortcutKey"
          data-testid="tree-find-file-control"
          class="gl-w-full sm:gl-w-auto"
          @click="handleFindFile"
        >
          {{ $options.i18n.findFile }}
        </gl-button>
        <!-- web ide -->
        <web-ide-link
          class="gl-w-full sm:!gl-ml-0 sm:gl-w-auto"
          data-testid="js-tree-web-ide-link"
          :project-id="projectIdAsNumber"
          :project-path="projectPath"
          :is-fork="isFork"
          :needs-to-fork="needsToFork"
          :gitpod-enabled="gitpodEnabled"
          :is-blob="isBlob"
          :show-edit-button="showEditButton"
          :show-web-ide-button="showWebIdeButton"
          :show-gitpod-button="showGitpodButton"
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
        <div v-if="!isReadmeView" class="project-code-holder gl-w-full sm:gl-w-auto">
          <div v-if="showCompactCodeDropdown" class="gl-flex gl-justify-end gl-gap-3">
            <compact-code-dropdown
              :ssh-url="sshUrl"
              :http-url="httpUrl"
              :kerberos-url="kerberosUrl"
              :xcode-url="xcodeUrl"
              :current-path="currentPath"
              :directory-download-links="downloadLinks"
            />
            <repository-overflow-menu v-if="comparePath" />
          </div>
          <template v-else>
            <code-dropdown
              class="git-clone-holder js-git-clone-holder gl-hidden sm:gl-inline-block"
              :ssh-url="sshUrl"
              :http-url="httpUrl"
              :kerberos-url="kerberosUrl"
              :xcode-url="xcodeUrl"
              :current-path="currentPath"
              :directory-download-links="downloadLinks"
            />
            <div class="gl-flex gl-items-stretch gl-gap-3 sm:gl-hidden">
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
              <repository-overflow-menu v-if="comparePath" />
            </div>
          </template>
        </div>
        <repository-overflow-menu
          v-if="comparePath && !showCompactCodeDropdown"
          class="gl-hidden sm:gl-inline-flex"
        />
      </div>

      <!-- Blob controls -->
      <blob-controls :project-path="projectPath" :ref-type="getRefType" :is-binary="isBinary" />
    </div>
  </section>
</template>
