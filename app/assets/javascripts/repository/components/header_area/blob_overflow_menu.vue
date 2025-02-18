<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { computed } from 'vue';
import { __ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import BlobDefaultActionsGroup from './blob_default_actions_group.vue';
import BlobButtonGroup from './blob_button_group.vue';

export const i18n = {
  dropdownLabel: __('Actions'),
};

export default {
  i18n,
  components: {
    GlDisclosureDropdown,
    BlobDefaultActionsGroup,
    BlobButtonGroup,
  },
  directives: {
    GlTooltipDirective,
  },
  inject: ['blobInfo'],
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
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
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
    v-gl-tooltip-directive.hover="$options.i18n.dropdownLabel"
    no-caret
    icon="ellipsis_v"
    data-testid="default-actions-container"
    :toggle-text="$options.i18n.dropdownLabel"
    text-sr-only
  >
    <blob-button-group
      v-if="isLoggedIn && !blobInfo.archived"
      :is-empty-repository="isEmptyRepository"
      :project-path="projectPath"
      :is-using-lfs="isUsingLfs"
    />
    <blob-default-actions-group
      :active-viewer-type="activeViewerType"
      :has-render-error="hasRenderError"
      :is-binary="isBinary"
      :is-empty="isEmpty"
      :override-copy="overrideCopy"
      @copy="onCopy"
    />
  </gl-disclosure-dropdown>
</template>
