<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { computed } from 'vue';
import glLicensedFeaturesMixin from '~/vue_shared/mixins/gl_licensed_features_mixin';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { isLoggedIn } from '~/lib/utils/common_utils';
import projectInfoQuery from 'ee_else_ce/repository/queries/project_info.query.graphql';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';
import BlobButtonGroup from 'ee_else_ce/repository/components/header_area/blob_button_group.vue';
import BlobDefaultActionsGroup from './blob_default_actions_group.vue';
import BlobDeleteFileGroup from './blob_delete_file_group.vue';
import BlobRepositoryActionsGroup from './blob_repository_actions_group.vue';

export const i18n = {
  dropdownLabel: __('File actions'),
  dropdownTooltip: __('Actions'),
  fetchError: __('An error occurred while fetching lock information, please try again.'),
};

export default {
  name: 'CEBlobOverflowMenu',
  i18n,
  components: {
    BlobRepositoryActionsGroup,
    GlDisclosureDropdown,
    BlobDefaultActionsGroup,
    BlobButtonGroup,
    BlobDeleteFileGroup,
  },
  directives: {
    GlTooltipDirective,
  },
  mixins: [glLicensedFeaturesMixin()],
  inject: ['blobInfo', 'currentRef'],
  provide() {
    return {
      blobInfo: computed(() => this.blobInfo ?? {}),
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    isBinaryFileType: {
      type: Boolean,
      required: false,
      default: false,
    },
    overrideCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEmptyRepository: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUsingLfs: {
      type: Boolean,
      required: false,
      default: false,
    },
    eeCanModifyFile: {
      type: Boolean,
      required: false,
      default: false,
    },
    eeCanCreateLock: {
      type: Boolean,
      required: false,
      default: false,
    },
    eeCanDestroyLock: {
      type: Boolean,
      required: false,
      default: false,
    },
    eeIsLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
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
      update({ project }) {
        this.userPermissions = project?.userPermissions || DEFAULT_BLOB_INFO.userPermissions;
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  data() {
    return {
      userPermissions: DEFAULT_BLOB_INFO.userPermissions,
      activeViewerType: SIMPLE_BLOB_VIEWER,
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    isLoading() {
      return this.$apollo?.queries.projectInfo.loading;
    },
    viewer() {
      return this.activeViewerType === RICH_BLOB_VIEWER
        ? this.blobInfo.richViewer
        : this.blobInfo.simpleViewer;
    },
    hasRenderError() {
      return Boolean(this.viewer.renderError);
    },
    canModifyFile() {
      return this.glLicensedFeatures.fileLocks ? this.eeCanModifyFile : true;
    },
    isLocked() {
      return this.glLicensedFeatures.fileLocks ? this.eeIsLocked : false;
    },
  },
  watch: {
    // Watch the URL 'plain' query value to know if the viewer needs changing.
    // This is the case when the user switches the viewer and then goes back through the history
    '$route.query.plain': {
      handler(plainValue) {
        this.updateViewerFromQueryParam(plainValue);
      },
    },
  },
  mounted() {
    this.updateViewerFromQueryParam(this.$route?.query?.plain);
  },
  methods: {
    updateViewerFromQueryParam(plainValue) {
      const hasRichViewer = Boolean(this.blobInfo.richViewer);
      const useSimpleViewer = plainValue === '1' || !hasRichViewer;
      this.switchViewer(useSimpleViewer ? SIMPLE_BLOB_VIEWER : RICH_BLOB_VIEWER);
    },
    switchViewer(newViewer) {
      this.activeViewerType = newViewer || SIMPLE_BLOB_VIEWER;
    },
    onCopy() {
      if (this.overrideCopy) {
        this.$emit('copy');
      }
    },
    onShowForkSuggestion() {
      this.$emit('showForkSuggestion');
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip-directive.hover="$options.i18n.dropdownTooltip"
    no-caret
    icon="ellipsis_v"
    data-testid="blob-overflow-menu"
    :toggle-text="$options.i18n.dropdownLabel"
    text-sr-only
    class="gl-mr-0"
    category="tertiary"
  >
    <blob-repository-actions-group :permalink-path="blobInfo.permalinkPath" />
    <blob-button-group
      v-if="isLoggedIn && !blobInfo.archived"
      :current-ref="currentRef"
      :project-path="projectPath"
      :is-using-lfs="isUsingLfs"
      :user-permissions="userPermissions"
      :is-loading="isLoading"
      :can-create-lock="eeCanCreateLock"
      :can-destroy-lock="eeCanDestroyLock"
      :is-replace-disabled="!canModifyFile && isLocked"
      :is-locked="isLocked"
      @showForkSuggestion="onShowForkSuggestion"
    />
    <blob-default-actions-group
      :active-viewer-type="activeViewerType"
      :has-render-error="hasRenderError"
      :is-binary-file-type="isBinaryFileType"
      :is-empty="isEmptyRepository"
      :override-copy="overrideCopy"
      @copy="onCopy"
    />
    <blob-delete-file-group
      v-if="isLoggedIn && !blobInfo.archived"
      :current-ref="currentRef"
      :is-empty-repository="isEmptyRepository"
      :is-using-lfs="isUsingLfs"
      :user-permissions="userPermissions"
      :disabled="!canModifyFile && isLocked"
      @showForkSuggestion="onShowForkSuggestion"
    />
  </gl-disclosure-dropdown>
</template>
