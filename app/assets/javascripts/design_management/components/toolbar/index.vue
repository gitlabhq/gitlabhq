<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlIcon, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import permissionsQuery from 'shared_queries/design_management/design_permissions.query.graphql';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __, s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';
import DeleteButton from '../delete_button.vue';
import DesignTodoButton from '../design_todo_button.vue';
import DesignNavigation from './design_navigation.vue';
import CloseButton from './close_button.vue';

export default {
  i18n: {
    downloadButtonLabel: s__('DesignManagement|Download design'),
    hideCommentsButtonLabel: s__('DesignManagement|Hide comments'),
    showCommentsButtonLabel: s__('DesignManagement|Show comments'),
  },
  components: {
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    DesignNavigation,
    DeleteButton,
    DesignTodoButton,
    CloseButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    isDeleting: {
      type: Boolean,
      required: true,
    },
    filename: {
      type: String,
      required: false,
      default: '',
    },
    updatedAt: {
      type: String,
      required: false,
      default: null,
    },
    updatedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLatestVersion: {
      type: Boolean,
      required: true,
    },
    image: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    design: {
      type: Object,
      required: true,
    },
    isSidebarOpen: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
      permissions: {
        createDesign: false,
      },
    };
  },
  apollo: {
    permissions: {
      query: permissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: (data) => data.project.issue.userPermissions,
    },
  },
  computed: {
    updatedText() {
      return sprintf(__('Updated %{updated_at} by %{updated_by}'), {
        updated_at: this.timeFormatted(this.updatedAt),
        updated_by: this.updatedBy.name,
      });
    },
    canDeleteDesign() {
      return this.permissions.createDesign;
    },
    issueTitle() {
      return this.design.issue.title;
    },
    toggleCommentsButtonLabel() {
      return this.isSidebarOpen
        ? this.$options.i18n.hideCommentsButtonLabel
        : this.$options.i18n.showCommentsButtonLabel;
    },
  },
  DESIGNS_ROUTE_NAME,
};
</script>

<template>
  <header
    class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-md-align-items-center gl-justify-content-space-between gl-max-w-full gl-bg-white gl-py-4 gl-pl-5 gl-border-b js-design-header"
  >
    <div
      class="gl-display-flex gl-flex-direction-row gl-align-items-center gl-mb-3 gl-md-mb-0 gl-overflow-hidden"
    >
      <div class="gl-overflow-hidden gl-display-flex gl-mr-3">
        <gl-skeleton-loader v-if="isLoading" :lines="1" />
        <h2 v-else class="gl-display-flex gl-overflow-hidden gl-m-0 gl-font-base">
          <span class="gl-text-truncate gl-text-gray-900 gl-text-decoration-none">
            {{ issueTitle }}
          </span>
          <gl-icon name="chevron-right" class="gl-text-gray-200 gl-flex-shrink-0" />
          <span class="gl-text-truncate gl-font-weight-normal">{{ filename }}</span>
        </h2>
        <small v-if="updatedAt" class="gl-text-gray-500">{{ updatedText }}</small>
      </div>
      <close-button class="gl-md-display-none gl-ml-auto" />
    </div>
    <div class="gl-display-flex gl-md-flex-direction-row gl-flex-shrink-0 gl-md-ml-auto gl-mr-5">
      <design-todo-button
        v-if="isLoggedIn"
        :design="design"
        class="gl-mr-3 gl-ml-0 gl-md-ml-3"
        @error="$emit('todoError', $event)"
      />
      <gl-button
        v-gl-tooltip.bottom
        :href="image"
        icon="download"
        :title="$options.i18n.downloadButtonLabel"
        :aria-label="$options.i18n.downloadButtonLabel"
      />
      <delete-button
        v-if="isLatestVersion && canDeleteDesign"
        v-gl-tooltip.bottom
        class="gl-ml-3"
        :is-deleting="isDeleting"
        button-variant="default"
        button-icon="archive"
        button-category="secondary"
        :title="s__('DesignManagement|Archive design')"
        @delete-selected-designs="$emit('delete')"
      />
      <gl-button
        v-gl-tooltip.bottom
        icon="comments"
        :title="toggleCommentsButtonLabel"
        :aria-label="toggleCommentsButtonLabel"
        class="gl-ml-3 gl-mr-6"
        data-testid="toggle-design-sidebar"
        @click="$emit('toggle-sidebar')"
      />
      <design-navigation :id="id" class="gl-ml-auto" />
    </div>
    <close-button class="gl-display-none gl-md-display-flex" />
  </header>
</template>
