<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { computed } from 'vue';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { isLoggedIn } from '~/lib/utils/common_utils';
import projectInfoQuery from 'ee_else_ce/repository/queries/project_info.query.graphql';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';
import BlobButtonGroup from 'ee_else_ce/repository/components/header_area/blob_button_group.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BlobDefaultActionsGroup from './blob_default_actions_group.vue';
import BlobDeleteFileGroup from './blob_delete_file_group.vue';
import PermalinkDropdownItem from './permalink_dropdown_item.vue';

export const i18n = {
  dropdownLabel: __('File actions'),
  dropdownTooltip: __('Actions'),
  fetchError: __('An error occurred while fetching lock information, please try again.'),
};

export default {
  name: 'CEBlobOverflowMenu',
  i18n,
  components: {
    PermalinkDropdownItem,
    GlDisclosureDropdown,
    BlobDefaultActionsGroup,
    BlobButtonGroup,
    BlobDeleteFileGroup,
  },
  directives: {
    GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
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
      default: undefined,
    },
    eeCanLock: {
      type: Boolean,
      required: false,
      default: undefined,
    },
    eeIsLocked: {
      type: Boolean,
      required: false,
      default: undefined,
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
        this.userPermissions = project?.userPermissions;
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  data() {
    return {
      userPermissions: DEFAULT_BLOB_INFO.userPermissions,
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    isLoading() {
      return this.$apollo?.queries.projectInfo.loading;
    },
    activeViewerType() {
      if (this.$route?.query?.plain !== '1') {
        const richViewer = document.querySelector('.blob-viewer[data-type="rich"]');
        if (richViewer) {
          return RICH_BLOB_VIEWER;
        }
      }
      return SIMPLE_BLOB_VIEWER;
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
      return this.eeCanModifyFile !== undefined ? this.eeCanModifyFile : true;
    },
    canLock() {
      return this.eeCanLock !== undefined ? this.eeCanLock : false;
    },
    isLocked() {
      return this.eeIsLocked !== undefined ? this.eeIsLocked : false;
    },
  },
  methods: {
    onCopy() {
      if (this.overrideCopy) {
        this.$emit('copy');
      }
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip-directive.hover="$options.i18n.dropdownTooltip"
    no-caret
    icon="ellipsis_v"
    data-testid="default-actions-container"
    :toggle-text="$options.i18n.dropdownLabel"
    text-sr-only
    class="gl-mr-0"
    category="tertiary"
  >
    <permalink-dropdown-item :permalink-path="blobInfo.permalinkPath" />
    <blob-button-group
      v-if="isLoggedIn && !blobInfo.archived"
      :current-ref="currentRef"
      :project-path="projectPath"
      :is-using-lfs="isUsingLfs"
      :user-permissions="userPermissions"
      :is-loading="isLoading"
      :can-lock="canLock"
      :is-replace-disabled="!canModifyFile"
      :is-locked="isLocked"
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
      :disabled="!canModifyFile"
    />
  </gl-disclosure-dropdown>
</template>
