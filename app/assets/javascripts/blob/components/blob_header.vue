<script>
import DefaultActions from 'jh_else_ce/blob/components/blob_header_default_actions.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import userInfoQuery from '../queries/user_info.query.graphql';
import applicationInfoQuery from '../queries/application_info.query.graphql';
import BlobFilepath from './blob_header_filepath.vue';
import ViewerSwitcher from './blob_header_viewer_switcher.vue';
import { SIMPLE_BLOB_VIEWER, BLAME_VIEWER } from './constants';
import TableOfContents from './table_contents.vue';

export default {
  components: {
    ViewerSwitcher,
    DefaultActions,
    BlobFilepath,
    TableOfContents,
    WebIdeLink: () => import('ee_else_ce/vue_shared/components/web_ide_link.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    currentUser: {
      query: userInfoQuery,
      error() {
        this.$emit('error');
      },
    },
    gitpodEnabled: {
      query: applicationInfoQuery,
      error() {
        this.$emit('error');
      },
    },
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
    isBlobPage: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideViewerSwitcher: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBinary: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeViewerType: {
      type: String,
      required: false,
      default: SIMPLE_BLOB_VIEWER,
    },
    hasRenderError: {
      type: Boolean,
      required: false,
      default: false,
    },
    showPath: {
      type: Boolean,
      required: false,
      default: true,
    },
    showPathAsLink: {
      type: Boolean,
      required: false,
      default: false,
    },
    overrideCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
    showForkSuggestion: {
      type: Boolean,
      required: false,
      default: false,
    },
    showWebIdeForkSuggestion: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    showBlameToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    showBlobSize: {
      type: Boolean,
      required: false,
      default: true,
    },
    editButtonVariant: {
      type: String,
      required: false,
      default: 'confirm',
    },
  },
  data() {
    return {
      viewer: this.hideViewerSwitcher ? null : this.activeViewerType,
      gitpodEnabled: false,
    };
  },
  computed: {
    showWebIdeLink() {
      return !this.blob.archived && this.blob.editBlobPath;
    },
    isEmpty() {
      return this.blob.rawSize === '0';
    },
    blobSwitcherDocIcon() {
      return this.blob.richViewer?.fileType === 'csv' ? 'table' : 'document';
    },
    projectIdAsNumber() {
      return getIdFromGraphQLId(this.projectId);
    },
  },
  watch: {
    viewer(newVal, oldVal) {
      if (newVal !== BLAME_VIEWER && newVal !== oldVal) {
        this.$emit('viewer-changed', newVal);
      }
    },
  },
  methods: {
    proxyCopyRequest() {
      this.$emit('copy');
    },
  },
};
</script>
<template>
  <div class="js-file-title file-title-flex-parent">
    <div class="gl-mb-3 gl-flex gl-gap-3 md:gl-mb-0">
      <table-of-contents v-if="!glFeatures.blobOverflowMenu" class="gl-pr-2" />

      <blob-filepath
        :blob="blob"
        :show-path="showPath"
        :show-as-link="showPathAsLink"
        :show-blob-size="showBlobSize"
      >
        <template #filepath-prepend>
          <slot name="prepend"></slot>
        </template>
      </blob-filepath>
    </div>

    <div class="file-actions gl-flex gl-flex-wrap gl-gap-3">
      <viewer-switcher
        v-if="!hideViewerSwitcher"
        v-model="viewer"
        :doc-icon="blobSwitcherDocIcon"
        :show-blame-toggle="showBlameToggle"
        :show-viewer-toggles="Boolean(blob.simpleViewer && blob.richViewer)"
        v-on="$listeners"
      />

      <table-of-contents v-if="glFeatures.blobOverflowMenu" class="gl-pr-2" />

      <web-ide-link
        v-if="showWebIdeLink"
        :show-edit-button="!isBinary"
        :button-variant="editButtonVariant"
        class="sm:!gl-ml-0"
        :edit-url="blob.editBlobPath"
        :web-ide-url="blob.ideEditPath"
        :needs-to-fork="showForkSuggestion"
        :needs-to-fork-with-web-ide="showWebIdeForkSuggestion"
        :show-pipeline-editor-button="Boolean(blob.pipelineEditorPath)"
        :pipeline-editor-url="blob.pipelineEditorPath"
        :gitpod-url="blob.gitpodBlobUrl"
        :show-gitpod-button="gitpodEnabled"
        :gitpod-enabled="currentUser && currentUser.gitpodEnabled"
        :project-path="projectPath"
        :project-id="projectIdAsNumber"
        :user-preferences-gitpod-path="currentUser && currentUser.preferencesGitpodPath"
        :user-profile-enable-gitpod-path="currentUser && currentUser.profileEnableGitpodPath"
        is-blob
        disable-fork-modal
        v-on="$listeners"
      />

      <slot name="actions"></slot>

      <default-actions
        v-if="!glFeatures.blobOverflowMenu || (glFeatures.blobOverflowMenu && !isBlobPage)"
        :raw-path="blob.externalStorageUrl || blob.rawPath"
        :active-viewer="viewer"
        :has-render-error="hasRenderError"
        :is-binary="isBinary"
        :environment-name="blob.environmentFormattedExternalUrl"
        :environment-path="blob.environmentExternalUrlForRouteMap"
        :is-empty="isEmpty"
        :override-copy="overrideCopy"
        @copy="proxyCopyRequest"
      />
    </div>
  </div>
</template>
