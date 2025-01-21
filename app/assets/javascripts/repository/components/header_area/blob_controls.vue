<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import getRefMixin from '~/repository/mixins/get_ref';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import initSourcegraph from '~/sourcegraph';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import ShortcutsBlob from '~/behaviors/shortcuts/shortcuts_blob';
import { shortcircuitPermalinkButton } from '~/blob/utils';
import BlobLinePermalinkUpdater from '~/blob/blob_line_permalink_updater';
import {
  keysFor,
  START_SEARCH_PROJECT_FILE,
  PROJECT_FILES_GO_TO_PERMALINK,
} from '~/behaviors/shortcuts/keybindings';
import { sanitize } from '~/lib/dompurify';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_BUTTON_CLICK } from '~/tracking/constants';
import { updateElementsVisibility } from '~/repository/utils/dom';
import blobControlsQuery from '~/repository/queries/blob_controls.query.graphql';
import { getRefType } from '~/repository/utils/ref_type';
import { TEXT_FILE_TYPE } from '../../constants';
import OverflowMenu from './blob_overflow_menu.vue';

export default {
  i18n: {
    findFile: __('Find file'),
    blame: __('Blame'),
    permalink: __('Permalink'),
    permalinkTooltip: __('Go to permalink'),
    errorMessage: __('An error occurred while loading the blob controls.'),
  },
  buttonClassList: 'sm:gl-w-auto gl-w-full sm:gl-mt-0 gl-mt-3',
  components: {
    GlButton,
    OverflowMenu,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
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
      error() {
        createAlert({ message: this.$options.i18n.errorMessage });
      },
    },
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
    isBinary: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      project: {},
    };
  },
  computed: {
    isLoadingRepositoryBlob() {
      return this.$apollo.queries.project.loading;
    },
    filePath() {
      return this.$route.params.path;
    },
    showBlobControls() {
      return this.filePath && this.$route.name === 'blobPathDecoded';
    },
    blobInfo() {
      return this.project?.repository?.blobs?.nodes[0] || {};
    },
    showBlameButton() {
      return !this.blobInfo.storedExternally && this.blobInfo.externalStorage !== 'lfs';
    },
    isBinaryFileType() {
      return this.isBinary || this.blobInfo.simpleViewer?.fileType !== TEXT_FILE_TYPE;
    },
    rawPath() {
      return this.blobInfo.externalStorageUrl || this.blobInfo.rawPath;
    },
    findFileShortcutKey() {
      return keysFor(START_SEARCH_PROJECT_FILE)[0];
    },
    findFileTooltip() {
      const { description } = START_SEARCH_PROJECT_FILE;
      const key = this.findFileShortcutKey;
      return shouldDisableShortcuts()
        ? null
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    permalinkShortcutKey() {
      return keysFor(PROJECT_FILES_GO_TO_PERMALINK)[0];
    },
    permalinkTooltip() {
      const description = this.$options.i18n.permalinkTooltip;
      const key = this.permalinkShortcutKey;
      return shouldDisableShortcuts()
        ? null
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    isEmpty() {
      return this.blobInfo.rawSize === '0';
    },
  },
  watch: {
    showBlobControls(shouldShow) {
      updateElementsVisibility('.tree-controls', !shouldShow);
    },
    blobInfo() {
      initSourcegraph();
      this.$nextTick(() => {
        this.initShortcuts();
        this.initLinksUpdate();
      });
    },
  },
  methods: {
    initShortcuts() {
      shortcircuitPermalinkButton();
      addShortcutsExtension(ShortcutsBlob);
    },
    initLinksUpdate() {
      // eslint-disable-next-line no-new
      new BlobLinePermalinkUpdater(
        document.querySelector('.tree-holder'),
        '.file-line-num[data-line-number], .file-line-num[data-line-number] *',
        document.querySelectorAll('.js-data-file-blob-permalink-url, .js-blob-blame-link'),
      );
    },
    handleFindFile() {
      InternalEvents.trackEvent(FIND_FILE_BUTTON_CLICK);
      Shortcuts.focusSearchFile();
    },
    onCopy() {
      navigator.clipboard.writeText(this.blobInfo.rawTextBlob);
    },
  },
};
</script>
<template>
  <div v-if="showBlobControls" class="gl-flex gl-flex-wrap gl-items-center gl-gap-3">
    <gl-button
      v-gl-tooltip.html="findFileTooltip"
      :aria-keyshortcuts="findFileShortcutKey"
      data-testid="find"
      :class="$options.buttonClassList"
      @click="handleFindFile"
    >
      {{ $options.i18n.findFile }}
    </gl-button>
    <gl-button
      v-if="showBlameButton"
      data-testid="blame"
      :href="blobInfo.blamePath"
      :class="$options.buttonClassList"
      class="js-blob-blame-link"
    >
      {{ $options.i18n.blame }}
    </gl-button>

    <gl-button
      v-gl-tooltip.html="permalinkTooltip"
      :aria-keyshortcuts="permalinkShortcutKey"
      data-testid="permalink"
      :href="blobInfo.permalinkPath"
      :class="$options.buttonClassList"
      class="js-data-file-blob-permalink-url"
    >
      {{ $options.i18n.permalink }}
    </gl-button>

    <overflow-menu
      v-if="!isLoadingRepositoryBlob && glFeatures.blobOverflowMenu"
      :name="blobInfo.name"
      :project-path="projectPath"
      :path="blobInfo.path"
      :raw-path="rawPath"
      :rich-viewer="blobInfo.richViewer"
      :simple-viewer="blobInfo.simpleViewer"
      :is-binary="isBinaryFileType"
      :environment-name="blobInfo.environmentFormattedExternalUrl"
      :environment-path="blobInfo.environmentExternalUrlForRouteMap"
      :is-empty="isEmpty"
      :override-copy="true"
      @copy="onCopy"
    />
  </div>
</template>
