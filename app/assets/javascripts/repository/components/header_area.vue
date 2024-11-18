<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { keysFor, START_SEARCH_PROJECT_FILE } from '~/behaviors/shortcuts/keybindings';
import { sanitize } from '~/lib/dompurify';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_BUTTON_CLICK } from '~/tracking/constants';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';

export default {
  name: 'HeaderArea',
  i18n: {
    compare: __('Compare'),
    findFile: __('Find file'),
  },
  components: {
    GlButton,
    RefSelector,
    Breadcrumbs,
    BlobControls,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'canCollaborate',
    'canEditTree',
    'canPushCode',
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
  },
  methods: {
    onInput(selectedRef) {
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
  <section class="nav-block gl-flex gl-flex-col gl-items-stretch sm:gl-flex-row">
    <div class="tree-ref-container mb-2 mb-md-0 gl-flex gl-flex-wrap gl-gap-2">
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

    <!-- Tree controls -->
    <div v-if="isTreeView" class="tree-controls gl-mb-3 gl-flex gl-flex-wrap gl-gap-3 sm:gl-mb-0">
      <!-- EE: = render_if_exists 'projects/tree/lock_link' -->
      <gl-button
        v-if="comparePath"
        data-testid="tree-compare-control"
        :href="comparePath"
        class="shortcuts-compare"
        >{{ $options.i18n.compare }}</gl-button
      >
      <gl-button
        v-gl-tooltip.html="findFileTooltip"
        :aria-keyshortcuts="findFileShortcutKey"
        data-testid="tree-find-file-control"
        class="gl-mt-3 gl-w-full sm:gl-mt-0 sm:gl-w-auto"
        @click="handleFindFile"
      >
        {{ $options.i18n.findFile }}
      </gl-button>
      <!-- web ide -->
      <!-- code + mobile panel -->
    </div>

    <!-- Blob controls -->
    <blob-controls :project-path="projectPath" :ref-type="getRefType" />
  </section>
</template>
