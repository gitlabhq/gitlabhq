<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import BlobDefaultActionsGroup from './blob_default_actions_group.vue';

export const i18n = {
  dropdownLabel: __('Actions'),
};

export default {
  i18n,
  components: {
    GlDisclosureDropdown,
    BlobDefaultActionsGroup,
    LockFileDropdownItem: () =>
      import('ee_component/repository/components/header_area/lock_file_dropdown_item.vue'),
  },
  directives: {
    GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    blobHash: {
      default: '',
    },
    canDownloadCode: {
      default: true,
    },
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    rawPath: {
      type: String,
      required: true,
    },
    richViewer: {
      type: Object,
      required: false,
      default: () => {},
    },
    simpleViewer: {
      type: Object,
      required: false,
      default: () => {},
    },
    isBinary: {
      type: Boolean,
      required: false,
      default: false,
    },
    environmentName: {
      type: String,
      required: false,
      default: null,
    },
    environmentPath: {
      type: String,
      required: false,
      default: null,
    },
    isEmpty: {
      type: Boolean,
      required: false,
      default: false,
    },
    overrideCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
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
      return this.activeViewerType === RICH_BLOB_VIEWER ? this.richViewer : this.simpleViewer;
    },
    hasRenderError() {
      return Boolean(this.viewer.renderError);
    },
    environmentTitle() {
      return sprintf(s__('BlobViewer|View on %{environmentName}'), {
        environmentName: this.environmentName,
      });
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
  <div>
    <gl-disclosure-dropdown
      v-gl-tooltip-directive.hover="$options.i18n.dropdownLabel"
      no-caret
      icon="ellipsis_v"
      data-testid="default-actions-container"
      :toggle-text="$options.i18n.dropdownLabel"
      text-sr-only
    >
      <lock-file-dropdown-item
        v-if="glFeatures.fileLocks"
        :name="name"
        :path="path"
        :project-path="projectPath"
      />
      <blob-default-actions-group
        :name="name"
        :path="path"
        :raw-path="rawPath"
        :active-viewer-type="activeViewerType"
        :has-render-error="hasRenderError"
        :is-binary="isBinary"
        :is-empty="isEmpty"
        :override-copy="overrideCopy"
        :environment-name="environmentName"
        :environment-path="environmentPath"
        @copy="onCopy"
      />
    </gl-disclosure-dropdown>
  </div>
</template>
