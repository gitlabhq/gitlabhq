<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { computed } from 'vue';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { isLoggedIn } from '~/lib/utils/common_utils';
import projectInfoQuery from 'ee_else_ce/repository/queries/project_info.query.graphql';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import { DEFAULT_BLOB_INFO } from '~/repository/constants';
import BlobDefaultActionsGroup from './blob_default_actions_group.vue';
import BlobButtonGroup from './blob_button_group.vue';
import BlobDeleteFileGroup from './blob_delete_file_group.vue';
import PermalinkDropdownItem from './permalink_dropdown_item.vue';

export const i18n = {
  dropdownLabel: __('File actions'),
  dropdownTooltip: __('Actions'),
  fetchError: __('An error occurred while fetching lock information, please try again.'),
};

export default {
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
    isBinary: {
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
        this.pathLocks = project?.pathLocks || DEFAULT_BLOB_INFO.pathLocks;
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
      pathLocks: DEFAULT_BLOB_INFO.pathLocks,
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
      :path-locks="pathLocks"
    />
    <blob-default-actions-group
      :active-viewer-type="activeViewerType"
      :has-render-error="hasRenderError"
      :is-binary="isBinary"
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
    />
  </gl-disclosure-dropdown>
</template>
